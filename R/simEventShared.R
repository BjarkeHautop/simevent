# Resample baseline covariates from old_vars, or pass them through as-is
# (useOldVars = TRUE). Returns list(sim_data, N, num_cov); N is overridden to
# nrow(old_vars) when useOldVars is TRUE.
.simEvent_resample_covariates <- function(old_vars, N, useOldVars) {
  if (is.null(colnames(old_vars)) && !is.null(old_vars)) {
    colnames(old_vars) <- paste0("L", seq_len(ncol(old_vars)))
  }
  num_cov <- ncol(old_vars)

  if (useOldVars) {
    sim_data <- data.frame(old_vars)
    N <- nrow(sim_data)
  } else if (!is.null(old_vars)) {
    sim_data <- data.frame(old_vars[
      sample(seq_len(nrow(old_vars)), N, TRUE),
      ,
      drop = FALSE
    ])
    colnames(sim_data) <- colnames(old_vars)
  } else {
    sim_data <- data.frame(matrix(ncol = 0, nrow = N))
  }

  list(sim_data = sim_data, N = N, num_cov = num_cov)
}

.simEvent_validate_add_cov <- function(add_cov) {
  if (!(is.null(add_cov) | is.list(add_cov))) {
    stop("add_cov needs to be list of random functions")
  }
}

.simEvent_num_events <- function(eta, nu, beta) {
  if (!is.null(eta)) {
    length(eta)
  } else if (!is.null(nu)) {
    length(nu)
  } else if (!is.null(beta)) {
    ncol(beta)
  } else {
    4
  }
}

# Builds the canonical N_stop x num_events beta matrix, named by
# c(cov_names, event_names). A user-supplied beta with rownames is matched by
# name (any order, any subset of full_names); missing rows default to 0. A
# user-supplied beta without rownames falls back to the historical positional
# behavior, requiring exactly N_stop rows in c(cov_names, event_names) order.
# event_names defaults to the historical N0, N1, ... labels, but a caller that
# already has real process names (e.g. simEventGraph()) can supply them
# directly, so beta/simmatrix/output columns use them end-to-end instead of
# requiring a name -> "N<k>" -> name round trip.
.simEvent_default_beta <- function(
  beta,
  N_stop,
  num_events,
  cov_names,
  event_names = paste0("N", seq(0, num_events - 1))
) {
  full_names <- c(cov_names, event_names)

  if (is.null(beta)) {
    beta <- matrix(0, nrow = N_stop, ncol = num_events)
    rownames(beta) <- full_names
    colnames(beta) <- event_names
    return(beta)
  }

  colnames(beta) <- event_names

  if (!is.null(rownames(beta))) {
    unknown <- setdiff(rownames(beta), full_names)
    if (length(unknown) > 0) {
      stop(
        "Unknown name(s) in rownames(beta): ",
        paste(unknown, collapse = ", "),
        ". Expected names are a subset of: ",
        paste(full_names, collapse = ", ")
      )
    }
    full_beta <- matrix(0, nrow = length(full_names), ncol = num_events)
    rownames(full_beta) <- full_names
    colnames(full_beta) <- event_names
    full_beta[rownames(beta), ] <- beta
    return(full_beta)
  }

  if (N_stop != nrow(beta)) {
    stop(
      "Number of rows in beta should equal the sum of number of events and ",
      "number of covariates (",
      N_stop,
      "). Alternatively, give beta ",
      "rownames matching covariate/event names so rows can be matched by ",
      "name instead of position."
    )
  }

  rownames(beta) <- full_names
  beta
}

.simEvent_default_eta_nu <- function(eta, nu, beta, num_events) {
  eta <- if (!is.null(eta)) eta else rep(0.1, num_events)
  nu <- if (!is.null(nu)) nu else rep(1.1, num_events)

  if (num_events != length(nu) || num_events != ncol(beta)) {
    stop("Length of eta should be equal to nu and number of columns of beta")
  }

  list(eta = eta, nu = nu)
}

.simEvent_default_at_risk <- function(at_risk, num_events) {
  if (is.null(at_risk)) {
    riskss <- rep(1, num_events)
    at_risk <- function(events) return(riskss)
  }
  at_risk
}

# Builds the ordered list of baseline covariate generators: L0 and A0 (from
# gen_L0/gen_A0, or their entries in add_cov, or defaults), followed by the
# remaining add_cov entries in the order supplied. gen_L0/gen_A0 are
# deprecated in favor of putting "L0"/"A0" entries directly in add_cov, but
# are still supported and merged in here for backwards compatibility.
.simEvent_build_cov_generators <- function(add_cov, gen_L0, gen_A0) {
  if (is.null(add_cov)) {
    add_cov <- list()
  }
  if (
    ("L0" %in% names(add_cov) && !is.null(gen_L0)) ||
      ("A0" %in% names(add_cov) && !is.null(gen_A0))
  ) {
    stop(
      "Specify baseline covariates L0/A0 either via gen_L0/gen_A0 or via ",
      "add_cov (e.g. add_cov = list(L0 = ..., A0 = ...)), not both."
    )
  }

  if (!("A0" %in% names(add_cov))) {
    if (is.null(gen_A0)) {
      gen_A0 <- function(N, L0) stats::rbinom(N, 1, 0.5)
    }
    add_cov <- c(list(A0 = gen_A0), add_cov)
  }
  if (!("L0" %in% names(add_cov))) {
    if (is.null(gen_L0)) {
      gen_L0 <- function(N) stats::runif(N)
    }
    add_cov <- c(list(L0 = gen_L0), add_cov)
  }

  # L0 must precede A0, since the default A0 generator depends on L0; keep
  # the relative order of any other add_cov entries as supplied.
  ord <- c("L0", "A0", setdiff(names(add_cov), c("L0", "A0")))
  add_cov[ord]
}

.simEvent_build_simmatrix <- function(N, num_events, cov_names, beta) {
  simmatrix <- matrix(0, nrow = N, ncol = length(cov_names) + num_events)
  colnames(simmatrix) <- c(cov_names, colnames(beta))
  simmatrix
}

.simEvent_apply_override_beta <- function(beta, override_beta) {
  if (!is.null(override_beta)) {
    for (bb in seq_along(override_beta)) {
      if (names(override_beta)[bb] %in% rownames(beta)) {
        beta[
          names(override_beta)[bb],
          names(override_beta[[bb]])
        ] <- override_beta[[bb]]
      } else {
        beta <- rbind(beta, matrix(0, nrow = 1, ncol = ncol(beta)))
        beta[nrow(beta), names(override_beta[[bb]])] <- override_beta[[bb]]
        rownames(beta)[nrow(beta)] <- names(override_beta)[bb]
      }
    }
  }
  beta
}

# Draws baseline covariates sequentially (in the order of `covs`), so a
# generator may depend on any covariate drawn before it: a generator's
# formal arguments (besides N) are matched by name against covariates
# already drawn, and passed in automatically.
.simEvent_draw_baseline <- function(simmatrix, N, covs) {
  drawn <- list()

  for (nm in names(covs)) {
    f <- covs[[nm]]
    arg_names <- setdiff(names(formals(f)), "N")
    missing_args <- setdiff(arg_names, names(drawn))
    if (length(missing_args) > 0) {
      stop(
        "covariate generator '",
        nm,
        "' depends on '",
        paste(missing_args, collapse = ", "),
        "', which has not been generated yet. A covariate can only depend ",
        "on covariates defined earlier in the same list."
      )
    }
    drawn[[nm]] <- do.call(f, c(list(N = N), drawn[arg_names]))
  }

  simmatrix[, names(covs)] <- do.call(cbind, drawn)
  simmatrix
}

.simEvent_at_risk_cov <- function(
  at_risk_cov,
  simmatrix,
  N_start,
  num_events,
  N
) {
  if (is.null(at_risk_cov)) {
    matrix(1, nrow = num_events, ncol = N)
  } else {
    out <- apply(simmatrix[, 1:(N_start - 1)], 1, at_risk_cov)
    if (nrow(out) != num_events) {
      stop("at_risk_cov needs to return a vector of length number of events")
    }
    out
  }
}

.simEvent_risk_user <- function(
  alive,
  simmatrix,
  N_start,
  N_stop,
  num_events,
  at_risk
) {
  vapply(
    alive,
    function(i) at_risk(simmatrix[i, N_start:N_stop]),
    numeric(num_events)
  )
}

.simEvent_store_result <- function(alive, T_k, Deltas, simmatrix) {
  kth_event <- data.table::data.table(
    ID = alive,
    Time = T_k[alive],
    Delta = Deltas
  )
  cbind(kth_event, data.table::as.data.table(simmatrix[alive, , drop = FALSE]))
}

.simEvent_check_max_events <- function(alive, idx, max_events) {
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

.simEvent_finalize <- function(res_list) {
  res <- data.table::rbindlist(res_list)
  data.table::setkeyv(res, "ID")
  res
}

.simEvent_run <- function(
  N,
  covs,
  beta,
  eta,
  nu,
  at_risk,
  term_deltas,
  max_cens,
  override_beta,
  max_events,
  lower,
  upper,
  at_risk_cov,
  event_names = NULL,
  ...
) {
  num_cov <- length(covs)

  # Determine number of events
  num_events <- .simEvent_num_events(eta, nu, beta)

  # Useful indices
  N_start <- num_cov + 1
  N_stop <- num_cov + num_events

  ############################ Default values ##################################

  # Set default values for beta, eta, and nu
  beta <- if (is.null(event_names)) {
    .simEvent_default_beta(beta, N_stop, num_events, names(covs))
  } else {
    .simEvent_default_beta(beta, N_stop, num_events, names(covs), event_names)
  }
  eta_nu <- .simEvent_default_eta_nu(eta, nu, beta, num_events)
  eta <- eta_nu$eta
  nu <- eta_nu$nu

  # Default at_risk
  at_risk <- .simEvent_default_at_risk(at_risk, num_events)

  # Matrix for storing values
  simmatrix <- .simEvent_build_simmatrix(N, num_events, names(covs), beta)

  # Filling out beta matrix
  beta <- .simEvent_apply_override_beta(beta, override_beta)

  ############################ Functions #######################################

  # Proportional hazard
  calculate_phi <- function(simmatrix) {
    if (nrow(beta) == N_stop) {
      return(exp(simmatrix %*% beta))
    } else {
      obj <- as.data.frame(simmatrix)
      obj <- cbind(obj, Times, Events)
      X <- sapply(rownames(beta), function(expr) {
        eval(parse(text = expr), envir = obj)
      })
      effects <- as.matrix(X) %*% beta
      return(exp(effects))
    }
  }

  # Whether all events share the same Weibull shape/scale, which enables a
  # closed-form (vectorized) inverse of the cumulative hazard; otherwise we
  # fall back to a per-individual numerical inverse coded in rcpp
  same_params <- all(nu[1] == nu) && all(eta[1] == eta)

  ############################ Initializing Simulations ########################

  # Draw baseline covariates
  simmatrix <- .simEvent_draw_baseline(simmatrix, N, covs)

  # Covariate dependent at_risk
  at_risk_cov <- .simEvent_at_risk_cov(
    at_risk_cov,
    simmatrix,
    N_start,
    num_events,
    N
  )

  # Initialize
  T_k <- rep(0, N) # Time 0
  alive <- 1:N # Keeping track of who is alive
  res_list <- vector("list", max_events) # For results
  idx <- 1 # Index
  Times <- matrix(0, ncol = max_events, nrow = N) # Times for override_beta
  colnames(Times) <- paste("T", seq(1, max_events), sep = "") # names for Times
  Events <- matrix(0, ncol = max_events, nrow = N) # Events for override_beta
  colnames(Events) <- paste("E", seq(1, max_events), sep = "") # names for Events

  ############################ Simulations #####################################

  while (length(alive) != 0) {
    n_alive <- length(alive)

    # Simulate time
    V <- -log(stats::runif(N))
    phi <- calculate_phi(simmatrix)
    phi_alive <- phi[alive, , drop = FALSE] # n_alive x num_events

    # At-risk indicator for every alive individual (num_events x n_alive)
    risk_user <- .simEvent_risk_user(
      alive,
      simmatrix,
      N_start,
      N_stop,
      num_events,
      at_risk
    )
    riskss_mat <- risk_user * at_risk_cov[, alive, drop = FALSE]

    if (same_params) {
      denom <- colSums(riskss_mat * eta * t(phi_alive))
      W <- (V[alive] / denom + T_k[alive]^nu[1])^(1 / nu[1]) - T_k[alive]
    } else {
      W <- vapply(
        seq_len(n_alive),
        function(j) {
          i <- alive[j]
          inverseScHaz(
            V[i],
            T_k[i],
            lower = lower,
            upper = upper,
            eta = eta,
            nu = nu,
            phi = phi[i, ],
            at_risk = riskss_mat[, j],
            ...
          )
        },
        numeric(1)
      )
    }
    T_k[alive] <- T_k[alive] + W

    # Maximal censoring time
    T_k[T_k > max_cens] <- max_cens
    t_alive <- T_k[alive]

    # Simulate event: vectorized event intensities across all alive individuals
    pow_mat <- outer(nu - 1, t_alive, FUN = function(p, tt) tt^p) # num_events x n_alive
    lambda_mat <- riskss_mat * eta * nu * pow_mat * t(phi_alive)

    censored <- t_alive >= max_cens
    if (any(censored)) {
      lambda_mat[, censored] <- c(1, rep(0, num_events - 1))
    }
    probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

    Deltas <- sampleEvents(probs_mat)

    # Update event counts
    simmatrix[cbind(alive, num_cov + Deltas + 1)] <-
      simmatrix[cbind(alive, num_cov + Deltas + 1)] + 1

    # Store data
    res_list[[idx]] <- .simEvent_store_result(alive, T_k, Deltas, simmatrix)
    if (idx < max_events) {
      Times[, idx] <- T_k # Saving the current time
      Events[alive, idx] <- Deltas # Saving the current event type
    }
    idx <- idx + 1

    # Who is still alive and uncensored?
    alive <- alive[!Deltas %in% term_deltas]

    .simEvent_check_max_events(alive, idx, max_events)
  }

  .simEvent_finalize(res_list)
}
