# Draws baseline covariates in declared order, as a named list of length-N
# numeric vectors, so a generator may depend on any covariate drawn before
# it (matched by argument name).
draw_baseline_covariates <- function(covs, n) {
  drawn <- list()
  for (nm in names(covs)) {
    f <- covs[[nm]]
    arg_names <- setdiff(names(formals(f)), "N")
    drawn[[nm]] <- do.call(f, c(list(N = n), drawn[arg_names]))
  }
  drawn
}

# Applies a sim_event_graph() `intervene` list to a graph: fixes an
# intervened covariate/sim_derived() to a constant generator, and scales an
# intervened process's baseline eta.
apply_intervention <- function(graph, intervene) {
  covariate_names <- names(graph$covariates)
  process_order <- .sim_graph_process_order(graph)

  covs <- lapply(graph$covariates, function(node) {
    if (inherits(node, "sim_derived")) {
      .sim_graph_wrap_derived(node$fn)
    } else {
      node$generator
    }
  })
  for (nm in intersect(names(intervene), covariate_names)) {
    value <- intervene[[nm]]
    covs[[nm]] <- local({
      force(value)
      function(N) rep(value, N)
    })
  }

  eta <- stats::setNames(
    vapply(graph$processes[process_order], `[[`, numeric(1), "eta"),
    process_order
  )
  for (nm in intersect(names(intervene), process_order)) {
    eta[nm] <- eta[nm] * intervene[[nm]]
  }

  list(covs = covs, eta = eta)
}

# For each process, the multiplicative hazard effect exp(sum of incoming
# sim_effect() coefs * current value of their `from`), evaluated by name
# against covariates/event counts. Returns a length(covariates[[1]]) x
# length(process_names) matrix.
process_hazard_multipliers <- function(
  effects,
  covariates,
  event_counts,
  process_names
) {
  n <- length(event_counts[[1]])
  log_phi <- matrix(
    0,
    nrow = n,
    ncol = length(process_names),
    dimnames = list(NULL, process_names)
  )
  for (eff in effects) {
    value <- covariates[[eff$from]]
    if (is.null(value)) {
      value <- event_counts[[eff$from]]
    }
    log_phi[, eff$to] <- log_phi[, eff$to] + eff$coef * value
  }
  exp(log_phi)
}

# Samples the time increment to each alive individual's next event, for one
# iteration of the simulation loop: the closed-form vectorized path when
# every process shares one Weibull shape/scale (same_params), else the
# per-individual numerical inverse (inverseScHazCpp) via inverseScHaz().
sample_next_event_times <- function(
  t_now,
  phi_alive,
  risk_alive,
  eta,
  nu,
  same_params,
  lower,
  upper
) {
  v <- -log(stats::runif(length(t_now)))

  if (same_params) {
    denom <- colSums(risk_alive * eta * t(phi_alive))
    (v / denom + t_now^nu[1])^(1 / nu[1]) - t_now
  } else {
    n_alive <- length(t_now)
    vapply(
      seq_len(n_alive),
      function(j) {
        inverseScHaz(
          v[j],
          t_now[j],
          lower = lower,
          upper = upper,
          eta = eta,
          nu = nu,
          phi = phi_alive[j, ],
          at_risk = risk_alive[, j]
        )
      },
      numeric(1)
    )
  }
}

# Samples which process fires next for each alive individual, given their
# updated times: vectorized event intensities across all alive individuals,
# then sampleEvents() draws one event type per individual, with
# censoring-time truncation. Returns a 0-indexed vector of process indices
# into process_names.
sample_event_types <- function(
  t_alive,
  phi_alive,
  risk_alive,
  eta,
  nu,
  max_cens
) {
  num_events <- length(eta)
  pow_mat <- outer(nu - 1, t_alive, FUN = function(p, tt) tt^p)
  lambda_mat <- risk_alive * eta * nu * pow_mat * t(phi_alive)

  censored <- t_alive >= max_cens
  if (any(censored)) {
    lambda_mat[, censored] <- c(1, rep(0, num_events - 1))
  }
  probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

  sampleEvents(probs_mat)
}

# Top-level driver, called by sim_event_graph(): draws baseline covariates,
# then repeatedly samples a next-event time and type for everyone still
# alive until all individuals have hit a censoring/terminal event.
run_sim_graph <- function(
  graph,
  n,
  intervene = list(),
  cens = 1,
  max_cens = Inf,
  max_events = 50,
  lower = 1e-25,
  upper = 1e8
) {
  process_order <- .sim_graph_process_order(graph)
  types <- vapply(graph$processes[process_order], `[[`, character(1), "type")
  term_deltas <- which(types %in% c("censoring", "terminal")) - 1L
  transient_names <- process_order[types == "transient"]

  intervened <- apply_intervention(graph, intervene)
  covariates <- draw_baseline_covariates(intervened$covs, n)

  eta <- intervened$eta[process_order]
  nu <- stats::setNames(
    vapply(graph$processes[process_order], `[[`, numeric(1), "nu"),
    process_order
  )
  same_params <- all(nu[1] == nu) && all(eta[1] == eta)

  at_risk_fn <- .sim_graph_at_risk(graph, process_order, cens)

  event_counts <- stats::setNames(
    replicate(length(process_order), rep(0, n), simplify = FALSE),
    process_order
  )

  t_k <- rep(0, n)
  alive <- seq_len(n)
  res_list <- vector("list", max_events)
  idx <- 1

  while (length(alive) != 0) {
    covariates_alive <- lapply(covariates, `[`, alive)
    event_counts_alive <- lapply(event_counts, `[`, alive)

    phi_alive <- process_hazard_multipliers(
      graph$effects,
      covariates_alive,
      event_counts_alive,
      process_order
    )
    risk_alive <- at_risk_fn(event_counts_alive)

    w <- sample_next_event_times(
      t_k[alive],
      phi_alive,
      risk_alive,
      eta,
      nu,
      same_params,
      lower,
      upper
    )
    t_k[alive] <- t_k[alive] + w
    t_k[t_k > max_cens] <- max_cens
    t_alive <- t_k[alive]

    deltas <- sample_event_types(
      t_alive,
      phi_alive,
      risk_alive,
      eta,
      nu,
      max_cens
    )

    for (k in seq_along(process_order)) {
      hit <- alive[deltas == (k - 1L)]
      event_counts[[process_order[k]]][hit] <- event_counts[[process_order[k]]][
        hit
      ] +
        1
    }

    result_cols <- c(
      list(id = alive, time = t_k[alive], delta = deltas),
      lapply(covariates, `[`, alive),
      stats::setNames(
        lapply(transient_names, function(nm) event_counts[[nm]][alive]),
        transient_names
      )
    )
    res_list[[idx]] <- data.table::as.data.table(result_cols)

    idx <- idx + 1
    alive <- alive[!deltas %in% term_deltas]

    if (length(alive) != 0 && idx > max_events) {
      stop(
        "max_events (",
        max_events,
        ") exceeded before a terminal event ",
        "occurred for all individuals. Increase max_events or adjust ",
        "at_risk/beta so that a terminal event becomes certain."
      )
    }
  }

  res <- data.table::rbindlist(res_list)
  data.table::setkeyv(res, "id")
  res[]
}
