#' Simulate Continuous Time-to-Event Data with Multiple Event Types and time dependent effects
#'
#' `simEventDataTdPhi` simulates event times and types for a cohort of individuals in a
#' counting process framework. It supports multiple event types (by default 4),
#' including terminal events, with intensities influenced by baseline covariates
#' and previous event history.
#'
#' The event intensities for event type \eqn{x} at time \eqn{t} are given by
#' \deqn{
#' \lambda^x(t) = \lambda_0^x(t) \exp(\beta_x^T L),
#' }
#' where the baseline intensity follows a Weibull hazard function:
#' \deqn{
#' \lambda_0^x(t) = \eta^x \nu^x t^{\nu^x - 1}.
#' }
#' Here, \eqn{L} is the vector of covariates and event counts, and \eqn{\beta^x} is
#' the vector of coefficients representing the effect of covariates and previous events on the intensity.
#' Additionally, the intensity decays (or grows) exponentially with the time since the most
#' recent occurrence of event \eqn{x}, controlled by \code{beta2}.
#'
#' Every simulated dataset includes two fixed baseline covariates, \code{L0} and
#' \code{A0}, in addition to any covariates supplied via \code{add_cov}. \code{L0}
#' is a baseline covariate and \code{A0} is a baseline treatment indicator whose
#' generator can depend on \code{L0}. Their distributions can be changed via
#' \code{gen_L0}/\code{gen_A0}.
#'
#' @inheritParams simEventData
#' @param beta2 Numeric vector. Regression coefficients corresponding to the effect of time since
#' last event on the events (N0, N1, ...). Default is 0 for all events (no time-decay effect).
#'
#' @inherit simEventData return
#'
#' @examples
#' # Simulate data for 10 individuals with default settings
#' sim_data <- simEventDataTdPhi(N = 10, beta2 = rep(0.01, 4))
#' head(sim_data)
#'
#' @export
simEventDataTdPhi <- function(
  N, # Number of individuals
  beta = NULL, # Effects of covariates and processes
  beta2 = NULL, # Effect of time since last event
  eta = NULL, # Shape parameters
  nu = NULL, # Scale parameters
  at_risk = NULL, # At risk indicator as function of events
  term_deltas = c(0, 1), # Terminal events
  max_cens = Inf, # Followup time
  add_cov = NULL, # Additional baseline covariates
  override_beta = NULL, # Override beta
  max_events = 10, # Maximal events per individual
  lower = 10^(-15), # Lower bound for ICH
  upper = 200, # Upper bound for ICH
  gen_A0 = NULL, # Generation of A0
  gen_L0 = NULL, # Generation of L0
  at_risk_cov = NULL, # At risk indicator as function of covariates
  ... # Additional technical arguments
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

  ############################ Default values ##################################

  # Set default values for beta, eta, and nu
  beta <- .simEvent_default_beta(beta, N_stop, num_events)
  beta2 <- if (!is.null(beta2)) beta2 else rep(0, num_events)
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

  ############################ Functions #######################################

  # Proportional hazard - Time independent part
  calculate_phi0 <- function(simmatrix) {
    if (nrow(beta) == N_stop) {
      return(exp(simmatrix %*% beta))
    }

    obj <- as.data.frame(simmatrix)
    obj <- cbind(obj, Times, Events)

    X <- sapply(rownames(beta), function(expr) {
      eval(parse(text = expr), envir = obj)
    })

    effects <- as.matrix(X) %*% beta

    exp(effects)
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
  T_star <- matrix(0, nrow = N, ncol = num_events) # Time since last event
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
    phi0 <- calculate_phi0(simmatrix)
    phi0_alive <- phi0[alive, , drop = FALSE] # n_alive x num_events
    T_star_alive <- T_star[alive, , drop = FALSE] # n_alive x num_events

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
        inverseScHazPhiTd(
          p = V[i],
          t = T_k[i],
          T_star = T_star[i, ],
          lower = lower,
          upper = upper,
          eta = eta,
          nu = nu,
          beta2 = beta2,
          phi0 = phi0[i, ],
          at_risk = riskss_mat[, j],
          ...
        )
      },
      numeric(1)
    )
    T_k[alive] <- T_k[alive] + W

    # Maximal censoring time
    T_k[T_k > max_cens] <- max_cens
    t_alive <- T_k[alive]

    # Simulate event: vectorized event intensities across all alive individuals
    diff_mat <- t_alive - T_star_alive # n_alive x num_events
    phi_now_mat <- phi0_alive * exp(-sweep(diff_mat, 2, beta2, "*"))

    pow_mat <- outer(nu - 1, t_alive, FUN = function(p, tt) tt^p) # num_events x n_alive
    lambda_mat <- riskss_mat * eta * nu * pow_mat * t(phi_now_mat)

    censored <- t_alive >= max_cens
    if (any(censored)) {
      lambda_mat[, censored] <- c(1, rep(0, num_events - 1))
    }
    probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

    Deltas <- sampleEvents(probs_mat)

    # Update last event time
    T_star[cbind(alive, Deltas + 1)] <- T_k[alive]

    # Update event counts
    simmatrix[cbind(alive, 2 + num_add_cov + Deltas + 1)] <-
      simmatrix[cbind(alive, 2 + num_add_cov + Deltas + 1)] + 1

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
