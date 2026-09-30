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
  process_names <- names(graph$processes)

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

  eta <- vapply(graph$processes, `[[`, numeric(1), "eta")
  for (nm in intersect(names(intervene), process_names)) {
    eta[nm] <- eta[nm] * intervene[[nm]]
  }

  list(covs = covs, eta = eta)
}

# The time of process `proc`'s most recent occurrence so far (per alive
# individual, i.e. per column of type_log/time_log), or -Inf where it hasn't
# occurred yet. type_log (process names) and time_log hold only the first
# n_rows rows (the individual's events so far).
.sim_graph_last_time <- function(type_log, time_log, proc, n_rows) {
  n <- ncol(time_log)
  if (n_rows == 0) {
    return(rep(-Inf, n))
  }
  hit <- type_log[seq_len(n_rows), , drop = FALSE] == proc
  vapply(
    seq_len(n),
    function(j) {
      w <- which(hit[, j])
      if (length(w) == 0) -Inf else time_log[max(w), j]
    },
    numeric(1)
  )
}

# The time of a process's k-th occurrence so far (per column), or Inf where
# fewer than k occurrences have happened yet.
.sim_graph_nth_time <- function(type_log, time_log, proc, k, n_rows) {
  n <- ncol(time_log)
  if (n_rows == 0) {
    return(rep(Inf, n))
  }
  hit <- type_log[seq_len(n_rows), , drop = FALSE] == proc
  vapply(
    seq_len(n),
    function(j) {
      w <- which(hit[, j])
      if (length(w) < k) Inf else time_log[w[k], j]
    },
    numeric(1)
  )
}

# Evaluation environment for a sim_effect() `from` expression: covariates and
# event counts bound by name (as before), plus `t` (current time) and the
# history accessors `last_time()`/`nth_time()`, which read the process name
# out of their unevaluated argument (so e.g. `last_time(checkup)` doesn't
# require `checkup` to resolve to anything itself). With rep_times > 1,
# covariates/event_counts/t cover rep_times time points per individual
# (rep(x, times = rep_times) layout) while the event logs cover each
# individual once, so the history accessors' results are replicated to match.
.sim_graph_effect_env <- function(
  covariates,
  event_counts,
  process_names,
  t,
  event_time_log,
  event_type_log,
  n_events_so_far,
  rep_times = 1
) {
  env <- list2env(c(covariates, event_counts), parent = parent.frame())
  env$t <- t
  env$last_time <- function(proc) {
    nm <- deparse(substitute(proc))
    if (!nm %in% process_names) {
      stop("last_time(): unknown process '", nm, "'")
    }
    rep(
      .sim_graph_last_time(event_type_log, event_time_log, nm, n_events_so_far),
      times = rep_times
    )
  }
  env$nth_time <- function(proc, k) {
    nm <- deparse(substitute(proc))
    if (!nm %in% process_names) {
      stop("nth_time(): unknown process '", nm, "'")
    }
    rep(
      .sim_graph_nth_time(
        event_type_log,
        event_time_log,
        nm,
        k,
        n_events_so_far
      ),
      times = rep_times
    )
  }
  env
}

# For each process, the multiplicative hazard effect exp(sum of incoming
# sim_effect() coefs * current value of their `from`). `from` naming a
# covariate or process directly is looked up by name; anything else is
# parsed and evaluated as an R expression against covariates/event
# counts/`t`/last_time()/nth_time().
# Returns a length(event_counts[[1]]) x length(process_names) matrix.
# rep_times: see .sim_graph_effect_env().
process_hazard_multipliers <- function(
  effects,
  covariates,
  event_counts,
  process_names,
  t = NULL,
  event_time_log = NULL,
  event_type_log = NULL,
  n_events_so_far = 0,
  rep_times = 1
) {
  n <- length(event_counts[[1]])
  log_phi <- matrix(
    0,
    nrow = n,
    ncol = length(process_names),
    dimnames = list(NULL, process_names)
  )
  env <- NULL
  for (eff in effects) {
    value <- covariates[[eff$from]]
    if (is.null(value)) {
      value <- event_counts[[eff$from]]
    }
    if (is.null(value)) {
      if (is.null(env)) {
        env <- .sim_graph_effect_env(
          covariates,
          event_counts,
          process_names,
          t,
          event_time_log,
          event_type_log,
          n_events_so_far,
          rep_times
        )
      }
      expr <- eff$parsed_from
      if (is.null(expr)) {
        expr <- str2lang(eff$from)
      }
      value <- eval(expr, envir = env)
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

# Whether any sim_effect() `from` expression refers to the current time `t`,
# so hazard multipliers change between events and have to be re-evaluated
# over time rather than once per event.
.sim_graph_uses_time <- function(effects) {
  any(vapply(
    effects,
    function(eff) {
      !is.null(eff$parsed_from) && "t" %in% all.vars(eff$parsed_from)
    },
    logical(1)
  ))
}

# TODO: Improve this

# Samples each alive individual's next event time when hazard multipliers
# depend on `t`. Between events only `t` changes, so time is split into steps
# on a global grid (multiples of time_step): within a step, multipliers are
# held at their value at the step's midpoint and the Weibull baseline is
# integrated exactly. The cumulative hazard is accumulated step by step
# (vectorized over individuals and over blocks of steps) until it crosses
# each individual's Exp(1) draw, and the event time is then solved for
# exactly within that step. Returns the new absolute event times (max_cens
# for anyone not reaching an event before it) and the multipliers in force
# at those times (for sample_event_types()).
sample_next_event_times_td <- function(
  t_now,
  covariates,
  event_counts,
  risk_alive,
  eta,
  nu,
  effects,
  process_names,
  event_time_log,
  event_type_log,
  n_events_so_far,
  max_cens,
  time_step,
  upper,
  max_points = 1e6
) {
  n <- length(t_now)
  num_proc <- length(process_names)
  v <- -log(stats::runif(n))

  event_time <- rep(max_cens, n)
  phi <- matrix(
    1,
    nrow = n,
    ncol = num_proc,
    dimnames = list(NULL, process_names)
  )
  left <- t_now
  cum_haz <- numeric(n)
  searching <- which(left < max_cens)
  block <- 16L

  while (length(searching) > 0) {
    m <- length(searching)
    b <- as.integer(max(1, min(block, floor(max_points / m))))

    # m x b step boundaries: from each individual's current position to the
    # next b grid points, capped at max_cens.
    grid <- outer(floor(left[searching] / time_step) + 1, 0:(b - 1), `+`)
    rights <- grid * time_step
    capped <- rights > max_cens
    rights[capped] <- max_cens
    lefts <- cbind(left[searching], rights[, -b, drop = FALSE])

    # Multipliers at every step midpoint, one row per (individual, step) in
    # rep(searching, times = b) order.
    point_ind <- rep(searching, times = b)
    phi_pts <- process_hazard_multipliers(
      effects,
      lapply(covariates, `[`, point_ind),
      lapply(event_counts, `[`, point_ind),
      process_names,
      t = as.vector((lefts + rights) / 2),
      event_time_log = event_time_log[, searching, drop = FALSE],
      event_type_log = event_type_log[, searching, drop = FALSE],
      n_events_so_far = n_events_so_far,
      rep_times = b
    )
    rate_ind <- t(risk_alive[, searching, drop = FALSE]) * rep(eta, each = m)
    rate_pts <- phi_pts * rate_ind[rep(seq_len(m), times = b), , drop = FALSE]

    # Baseline cumulative hazard over each step. Step ends are grid points,
    # so their powers come from one lookup table per process instead of
    # m * b pow() calls.
    grid_min <- min(grid)
    grid_pts <- seq(grid_min, max(grid)) * time_step
    base_pts <- matrix(0, nrow = m * b, ncol = num_proc)
    for (k in seq_len(num_proc)) {
      pow_table <- grid_pts^nu[k]
      right_pow <- matrix(pow_table[grid - grid_min + 1], nrow = m)
      right_pow[capped] <- max_cens^nu[k]
      left_pow <- cbind(left[searching]^nu[k], right_pow[, -b, drop = FALSE])
      base_pts[, k] <- right_pow - left_pow
    }
    step_haz <- matrix(rowSums(rate_pts * base_pts), nrow = m, ncol = b)

    cum_steps <- step_haz
    cum_steps[, 1] <- cum_steps[, 1] + cum_haz[searching]
    for (j in seq_len(b)[-1]) {
      cum_steps[, j] <- cum_steps[, j - 1] + step_haz[, j]
    }
    crossed <- cum_steps >= v[searching]
    hit <- which(rowSums(crossed) > 0)

    if (length(hit) > 0) {
      step <- max.col(crossed[hit, , drop = FALSE], ties.method = "first")
      at <- cbind(hit, step)
      point <- (step - 1) * m + hit
      remaining <- v[searching[hit]] - (cum_steps[at] - step_haz[at])
      event_time[searching[hit]] <- .sim_graph_solve_in_step(
        lefts[at],
        rights[at],
        rate_pts[point, , drop = FALSE],
        nu,
        remaining
      )
      phi[searching[hit], ] <- phi_pts[point, ]
    }

    miss <- setdiff(seq_len(m), hit)
    left[searching[miss]] <- rights[miss, b]
    cum_haz[searching[miss]] <- cum_steps[miss, b]
    searching <- searching[miss][left[searching[miss]] < max_cens]

    if (any(left[searching] > upper)) {
      stop(
        "No event before time ",
        upper,
        " for some individual(s): their total hazard is (close to) zero."
      )
    }
    block <- min(block * 2L, 4096L)
  }

  list(time = event_time, phi = phi)
}

# Solves sum_k rate[, k] * (x^nu[k] - left^nu[k]) = remaining for x in
# [left, right], per row: closed form when every process shares one shape
# nu, otherwise bisection (the left-hand side is increasing in x).
.sim_graph_solve_in_step <- function(left, right, rate, nu, remaining) {
  if (all(nu == nu[1])) {
    x <- (remaining / rowSums(rate) + left^nu[1])^(1 / nu[1])
    return(pmin(pmax(x, left), right))
  }
  lo <- left
  hi <- right
  base_left <- outer(left, nu, `^`)
  for (i in seq_len(60)) {
    mid <- (lo + hi) / 2
    above <- rowSums(rate * (outer(mid, nu, `^`) - base_left)) >= remaining
    hi[above] <- mid[above]
    lo[!above] <- mid[!above]
  }
  (lo + hi) / 2
}

# Samples which process fires next for each alive individual, given their
# updated times: vectorized event intensities across all alive individuals,
# then sampleEvents() draws one event type per individual. Anyone who has
# reached max_cens gets "max_cens" instead of a process. Returns a character
# vector of process names (names(eta)).
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

  # Placeholder intensities for those reaching max_cens (overwritten below),
  # so their columns don't divide by zero.
  censored <- t_alive >= max_cens
  lambda_mat[, censored] <- 1
  probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

  # sampleEvents() returns 0-indexed rows of probs_mat.
  events <- names(eta)[sampleEvents(probs_mat) + 1L]
  events[censored] <- "max_cens"
  events
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
  upper = 1e8,
  time_step = 0.01
) {
  process_names <- names(graph$processes)
  types <- vapply(graph$processes, `[[`, character(1), "type")
  ending_events <- c(
    process_names[types %in% c("censoring", "terminal")],
    "max_cens"
  )
  transient_names <- process_names[types == "transient"]

  intervened <- apply_intervention(graph, intervene)
  covariates <- draw_baseline_covariates(intervened$covs, n)

  eta <- intervened$eta
  nu <- vapply(graph$processes, `[[`, numeric(1), "nu")
  same_params <- all(nu[1] == nu) && all(eta[1] == eta)

  at_risk_fn <- .sim_graph_at_risk(graph, cens)
  uses_time <- .sim_graph_uses_time(graph$effects)

  event_counts <- stats::setNames(
    replicate(length(process_names), rep(0, n), simplify = FALSE),
    process_names
  )

  # Full per-individual event log (time + which process, one row per event
  # so far), so sim_effect() expressions can use last_time()/nth_time().
  event_time_log <- matrix(0, nrow = max_events, ncol = n)
  event_type_log <- matrix(NA_character_, nrow = max_events, ncol = n)

  t_k <- rep(0, n)
  alive <- seq_len(n)
  res_list <- vector("list", max_events)
  idx <- 1

  while (length(alive) != 0) {
    covariates_alive <- lapply(covariates, `[`, alive)
    event_counts_alive <- lapply(event_counts, `[`, alive)

    risk_alive <- at_risk_fn(event_counts_alive)

    if (uses_time) {
      draw <- sample_next_event_times_td(
        t_k[alive],
        covariates_alive,
        event_counts_alive,
        risk_alive,
        eta,
        nu,
        graph$effects,
        process_names,
        event_time_log = event_time_log[, alive, drop = FALSE],
        event_type_log = event_type_log[, alive, drop = FALSE],
        n_events_so_far = idx - 1,
        max_cens = max_cens,
        time_step = time_step,
        upper = upper
      )
      t_k[alive] <- draw$time
      phi_alive <- draw$phi
    } else {
      phi_alive <- process_hazard_multipliers(
        graph$effects,
        covariates_alive,
        event_counts_alive,
        process_names,
        t = t_k[alive],
        event_time_log = event_time_log[, alive, drop = FALSE],
        event_type_log = event_type_log[, alive, drop = FALSE],
        n_events_so_far = idx - 1
      )
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
    }
    t_k[t_k > max_cens] <- max_cens
    t_alive <- t_k[alive]

    events <- sample_event_types(
      t_alive,
      phi_alive,
      risk_alive,
      eta,
      nu,
      max_cens
    )

    for (nm in process_names) {
      hit <- alive[events == nm]
      event_counts[[nm]][hit] <- event_counts[[nm]][hit] + 1
    }

    event_time_log[idx, ] <- t_k
    event_type_log[idx, alive] <- events

    result_cols <- c(
      list(id = alive, time = t_k[alive], event = events),
      lapply(covariates, `[`, alive),
      stats::setNames(
        lapply(transient_names, function(nm) event_counts[[nm]][alive]),
        transient_names
      )
    )
    res_list[[idx]] <- data.table::as.data.table(result_cols)

    idx <- idx + 1
    alive <- alive[!events %in% ending_events]

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

  event <- NULL
  res <- data.table::rbindlist(res_list)
  event_levels <- c(process_names, if (is.finite(max_cens)) "max_cens")
  res[, event := factor(event, levels = event_levels)]
  data.table::setkeyv(res, "id")
  res[]
}
