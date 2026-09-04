#' Simulate Event Data with Time-Varying Effects
#'
#' `simEventTV` simulates event data with the option of adding time-varying effects.
#' The function is built up in the same way as `simEventData`, with the additional
#' arguments `tv_eff` and `t_prime`, which specify the change of the beta matrix at
#' time `t_prime`.
#'
#' @inheritParams simEventData
#' @param tv_eff Matrix. Time-varying changes to `beta`, applied at time `t_prime`. Must have same dimensions as `beta`.
#' @param t_prime Numeric. Time at which `tv_eff` is added to `beta`.
#'
#' @return A `data.table` with columns:
#'   \item{ID:}{Individual identifier}
#'   \item{Time:}{Time of event}
#'   \item{Delta:}{Type of event}
#'   \item{L0:}{Baseline covariate}
#'   \item{A0:}{Baseline treatment}
#'   \item{N0, N1, ...:}{Cumulative event counts}
#'   \item{L1, L2, ...:}{Additional covariates (if specified)}
#'
#' @examples
#' eta <- rep(0.1, 2)
#' simEventTV(N = 100, t_prime = 1, eta = eta, term_deltas = c(0, 1))
#'
#' @export
#'
simEventTV <- function(
  N, # Number of individuals
  beta = NULL, # Effects
  tv_eff = NULL, # Time varying effects
  t_prime = Inf, # Time of change in effects
  eta = NULL, # Shape parameters
  nu = NULL, # Scale parameters
  at_risk = NULL, # Function defining the setting
  term_deltas = c(0, 1), # Terminal events
  max_cens = Inf, # Followup time
  add_cov = NULL, # Additional baseline covariates
  override_beta = NULL, # Override beta
  max_events = 10, # Maximal events per individual
  lower = 10^(-15), # Lower bound for ICH
  upper = 200, # Upper bound for ICH
  gen_A0 = NULL, # Generation of A0
  gen_L0 = NULL, # Generation of L0
  at_risk_cov = NULL # At risk indicator as function of covariates
) {
  ID <- NULL

  ############################ Check and useful quantities #####################
  .simEvent_validate_add_cov(add_cov)

  # Number of additional baseline covariates
  num_add_cov <- length(add_cov)

  # Determine number of events
  num_events <- .simEvent_num_events(eta, nu, beta)

  # Useful indices
  N_start <- 3 + num_add_cov
  N_stop <- 2 + num_add_cov + num_events

  # Check of dimensions of tv_eff
  if (!is.null(tv_eff) && any(dim(tv_eff) != c(N_stop, num_events))) {
    stop(sprintf("Dimensions of tv_eff must be (%d, %d)", N_stop, num_events))
  }

  ############################ Default values ##################################

  # Set default values for beta, eta, and nu
  beta <- .simEvent_default_beta(beta, N_stop, num_events)
  tv_eff <- if (!is.null(tv_eff)) {
    tv_eff
  } else {
    matrix(0, nrow = N_stop, ncol = num_events)
  }
  eta_nu <- .simEvent_default_eta_nu(eta, nu, beta, num_events)
  eta <- eta_nu$eta
  nu <- eta_nu$nu

  # Default at_risk
  at_risk <- .simEvent_default_at_risk(at_risk, num_events)

  # Default A0 and L0 generation
  gens <- .simEvent_default_gen(gen_A0, gen_L0)
  gen_A0 <- gens$gen_A0
  gen_L0 <- gens$gen_L0

  # Matrix for storing values
  simmatrix <- .simEvent_build_simmatrix(
    N,
    num_events,
    num_add_cov,
    add_cov,
    beta
  )

  rownames(beta) <- colnames(simmatrix)

  # Filling out beta matrix
  beta <- .simEvent_apply_override_beta(beta, override_beta)

  # In case of time varying effects
  beta_prime <- beta
  beta_prime[1:N_stop, ] <- beta[1:N_stop, ] + tv_eff

  ############################ Functions #######################################

  # Proportional hazard
  calculate_phi <- function(simmatrix, beta = beta) {
    if (nrow(beta) == N_stop) {
      return(exp(simmatrix %*% beta))
    } else {
      obj <- as.data.frame(simmatrix)
      X <- sapply(rownames(beta), function(expr) {
        eval(parse(text = expr), envir = obj)
      })
      effects <- as.matrix(X) %*% beta
      return(exp(effects))
    }
  }

  ############################ Initializing Simulations ########################

  # Draw baseline covariates
  simmatrix <- .simEvent_draw_baseline(
    simmatrix,
    N,
    num_add_cov,
    add_cov,
    gen_L0,
    gen_A0
  )

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

  ############################ Simulations #####################################

  while (length(alive) != 0) {
    n_alive <- length(alive)

    # Simulate time
    V <- -log(stats::runif(N))
    phi <- calculate_phi(simmatrix, beta)
    phi_prime <- calculate_phi(simmatrix, beta_prime)
    phi_alive <- phi[alive, , drop = FALSE] # n_alive x num_events
    phi_prime_alive <- phi_prime[alive, , drop = FALSE]

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

    W <- vapply(
      seq_len(n_alive),
      function(j) {
        i <- alive[j]
        inverseScHazTV(
          V[i],
          T_k[i],
          lower = lower,
          upper = upper,
          t_prime = t_prime,
          eta = eta,
          nu = nu,
          phi = phi[i, ],
          phi_prime = phi_prime[i, ],
          at_risk = riskss_mat[, j]
        )
      },
      numeric(1)
    )
    T_k[alive] <- T_k[alive] + W

    # Maximal censoring time
    T_k[T_k > max_cens] <- max_cens
    t_alive <- T_k[alive]

    # Simulate event: vectorized event intensities across all alive individuals
    use_prime <- t_alive > t_prime
    phi_use <- phi_alive
    phi_use[use_prime, ] <- phi_prime_alive[use_prime, ]

    pow_mat <- outer(nu - 1, t_alive, FUN = function(p, tt) tt^p) # num_events x n_alive
    lambda_mat <- riskss_mat * eta * nu * pow_mat * t(phi_use)

    censored <- t_alive == max_cens
    if (any(censored)) {
      lambda_mat[, censored] <- c(1, rep(0, num_events - 1))
    }
    probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

    Deltas <- sampleEvents(probs_mat)

    # Update event counts
    simmatrix[cbind(alive, 2 + num_add_cov + Deltas + 1)] <-
      simmatrix[cbind(alive, 2 + num_add_cov + Deltas + 1)] + 1

    # Store data
    res_list[[idx]] <- .simEvent_store_result(alive, T_k, Deltas, simmatrix)
    idx <- idx + 1

    # Who is still alive and uncensored?
    alive <- alive[!Deltas %in% term_deltas]

    .simEvent_check_max_events(alive, idx, max_events)
  }

  .simEvent_finalize(res_list)
}
