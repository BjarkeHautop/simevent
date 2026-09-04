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

.simEvent_default_beta <- function(beta, N_stop, num_events) {
  beta <- if (!is.null(beta)) {
    beta
  } else {
    matrix(0, nrow = N_stop, ncol = num_events)
  }
  colnames(beta) <- paste0("N", seq(0, num_events - 1))

  if (N_stop != nrow(beta)) {
    stop(
      "Number of rows in beta should equal the sum of number of events and
         number of additional covariates + 2"
    )
  }

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

.simEvent_default_gen <- function(gen_A0, gen_L0) {
  if (is.null(gen_A0)) {
    gen_A0 <- function(N, L0) stats::rbinom(N, 1, 0.5)
  }
  if (is.null(gen_L0)) {
    gen_L0 <- function(N) stats::runif(N)
  }
  list(gen_A0 = gen_A0, gen_L0 = gen_L0)
}

.simEvent_build_simmatrix <- function(
  N,
  num_events,
  num_add_cov,
  add_cov,
  beta
) {
  simmatrix <- matrix(0, nrow = N, ncol = (2 + num_events + num_add_cov))

  if (is.null(names(add_cov)) && num_add_cov != 0) {
    colnames(simmatrix) <- c(
      "L0",
      "A0",
      paste0("L", seq_len(num_add_cov)),
      colnames(beta)
    )
  } else {
    colnames(simmatrix) <- c("L0", "A0", names(add_cov), colnames(beta))
  }

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

.simEvent_draw_baseline <- function(
  simmatrix,
  N,
  num_add_cov,
  add_cov,
  gen_L0,
  gen_A0
) {
  simmatrix[, 1] <- gen_L0(N) # L0
  simmatrix[, 2] <- gen_A0(N, simmatrix[, 1]) # A0

  if (num_add_cov != 0) {
    simmatrix[, 3:(2 + length(add_cov))] <- sapply(add_cov, function(f) f(N))
  }

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
