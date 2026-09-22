#' Simulate Continuous Time-to-Event Data with Multiple Event Types
#'
#' `simEventData` simulates event times and types for a cohort of individuals in a
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
#'
#' Every simulated dataset includes two baseline covariates, \code{L0} (a
#' baseline covariate, Uniform(0,1) by default) and \code{A0} (a baseline
#' treatment indicator, Bernoulli(0.5) by default), followed by any
#' covariates supplied via \code{add_cov}. \code{L0}/\code{A0} are just the
#' first two entries of the covariate-generation list: a generator may depend
#' on any covariate defined earlier in that list by name (e.g. the default
#' \code{A0} generator takes \code{L0} as an argument), so \code{add_cov} can
#' itself supply "L0"/"A0" entries, or later covariates conditional on
#' earlier ones (see \code{add_cov} below).
#'
#' @param N Integer. Number of individuals to simulate.
#' @param beta Numeric matrix. Regression coefficients matrix where columns correspond to event types (N0, N1, ...) and rows correspond to covariates (L0, A0, L1, L2, ...) and event counts (N0, N1, ...). If \code{beta} has rownames, rows are matched by name against covariate/event names (any order, any subset; missing rows default to 0) instead of requiring a fixed row order. Default is a zero matrix.
#' @param eta Numeric vector. Shape parameters of the Weibull baseline intensity for each event type. Default is 0.1 for all events.
#' @param nu Numeric vector. Scale parameters of the Weibull baseline intensity for each event type. Default is 1.1 for all events.
#' @param at_risk Function. Function determining if an individual is at risk for each event type, given their current event counts. Takes a numeric vector of event counts and returns a binary vector. Default returns 1 for all events.
#' @param term_deltas Integer vector. Event types considered terminal (after which no further events occur). Default is c(0, 1).
#' @param max_cens Numeric. Maximum censoring time. Events occurring after this time are censored. Default is Inf (no maximal censoring).
#' @param add_cov Named list of functions. Functions generating baseline covariates, drawn in list order after \code{L0}/\code{A0} (unless the list itself supplies "L0"/"A0", replacing the defaults). Each function takes integer N and, optionally, any subset of the names of covariates defined earlier (including L0/A0), matched by argument name, and returns a numeric vector of length N. Default is NULL.
#' @param override_beta Named list. Used to specify entries of the \code{beta} matrix to override defaults. For example, \code{list("L0" = c("N1" = 2))} sets the effect of L0 on N1 to 2.
#' @param max_events Integer. Maximum number of events to simulate per individual. Default is 10.
#' @param lower Numeric. Lower bound for root-finding in inverse cumulative hazard calculations. Default is \eqn{10^{-15}}.
#' @param upper Numeric. Upper bound for root-finding in inverse cumulative hazard calculations. Default is 200.
#' @param gen_A0 Function. Deprecated; use \code{add_cov = list(A0 = ...)} instead. Function to generate the baseline treatment covariate A0. Takes N and L0 as inputs. Default is a Bernoulli(0.5) random variable.
#' @param gen_L0 Function. Deprecated; use \code{add_cov = list(L0 = ...)} instead. Function to generate the baseline covariate L0. Takes N as inputs. Default is a Uniform(0,1) random variable.
#' @param at_risk_cov Function. Function determining if an individual is at risk for each event type, given their covariates. Takes a matrix of covariates and returns a binary matrix. Default returns 1 for all events and all individuals.
#' @param ... Additional technical arguments.
#'
#' @return A \code{data.table} with columns:
#' \item{ID}{Individual identifier}
#' \item{Time}{Time of event}
#' \item{Delta}{Event type at time}
#' \item{L0}{Baseline covariate}
#' \item{A0}{Baseline treatment}
#' \item{L1, L2, ...}{Additional baseline covariates if specified}
#' \item{N0, N1, ...}{Event counts up to the current event}
#'
#' @examples
#' # Simulate data for 10 individuals with default settings
#' sim_data <- simEventData(N = 10)
#' head(sim_data)
#'
#' @export
simEventData <- function(
  N, # Number of individuals
  beta = NULL, # Effects
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
  ############################ Check and useful quantities #####################
  .simEvent_validate_add_cov(add_cov)

  # Ordered list of baseline covariate generators (L0, A0, then add_cov)
  covs <- .simEvent_build_cov_generators(add_cov, gen_L0, gen_A0)

  .simEvent_run(
    N = N,
    covs = covs,
    beta = beta,
    eta = eta,
    nu = nu,
    at_risk = at_risk,
    term_deltas = term_deltas,
    max_cens = max_cens,
    override_beta = override_beta,
    max_events = max_events,
    lower = lower,
    upper = upper,
    at_risk_cov = at_risk_cov,
    ...
  )
}
