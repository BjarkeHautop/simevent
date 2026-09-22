#' Simulate Event History Data from a Generic Process Specification
#'
#' `sim.generic` simulates multistate event history data from a set of
#' user-specified baseline covariates, event processes (with Weibull
#' intensities and Cox-type effects), and their effects on one another, by
#' translating the specification into a \code{\link{sim_graph}()} and
#' simulating from it.
#'
#' Where the preset wrapper functions (\code{\link{simCRdata}},
#' \code{\link{simDisease}}, \code{\link{simSurvData}}, etc.) hard-code a
#' fixed set of processes and effects, \code{sim.generic} lets you describe
#' an arbitrary number of named processes and baseline covariates directly.
#' See \code{vignette("sim-generic", package = "simevent")} for worked
#' examples, including how to reproduce each preset wrapper's default
#' behavior.
#'
#' @param baseline Named list of baseline covariate generator functions, each
#'   taking \code{N} and returning a numeric vector of length \code{N}.
#' @param processes Named list of process specifications. Each entry is a
#'   list with at least a \code{type} (one of \code{"censoring"},
#'   \code{"terminal"}, \code{"one.jump"}, or any other value for a recurrent
#'   process), and Weibull intensity parameters \code{eta}/\code{nu}.
#' @param effects List of \code{c(from, to, coefficient)} triples specifying
#'   Cox-type effects of a baseline covariate or process on another
#'   process's intensity. \code{from}/\code{to} are process or baseline
#'   covariate names, matching the names used in \code{baseline}/
#'   \code{processes}.
#' @param sim.object Optional list with \code{baseline}/\code{processes}/
#'   \code{effects} entries, used as a fallback when none of
#'   \code{baseline}, \code{processes}, or \code{effects} are supplied
#'   directly (so, for example, an empty \code{effects = list()} is honored
#'   as "no effects" rather than triggering the fallback).
#' @param cens Numeric. At-risk indicator scaling for the censoring process.
#'   Default 1.
#' @param alpha.intervention Named list of multiplicative interventions on
#'   process intensities (\code{eta}), keyed by process name.
#' @param baseline.intervention Named list of interventions that fix a
#'   baseline covariate to a constant value, keyed by covariate name.
#' @param n Integer. Number of individuals to simulate. Default 500.
#' @param browse Logical. If \code{TRUE}, drop into \code{browser()} before
#'   simulating. Default \code{FALSE}.
#'
#' @return A \code{data.table} of simulated event history data with columns
#'   \code{id}, \code{time}, \code{delta}, the baseline covariates, and one
#'   column per non-terminal process.
#'
#' @examples
#' baseline <- list(L0 = function(N) rbinom(N, 1, 0.4))
#' processes <- list(
#'   censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
#'   death = list(type = "terminal", eta = 0.1, nu = 1.1)
#' )
#' effects <- list(c("L0", "death", 1))
#' data <- sim.generic(baseline, processes, effects, n = 100)
#' head(data)
#'
#' @export
sim.generic <- function(
  baseline = list(),
  processes = list(),
  effects = list(),
  sim.object = list(),
  cens = 1,
  alpha.intervention = list(),
  baseline.intervention = list(),
  n = 500,
  browse = FALSE
) {
  if (missing(baseline) && missing(processes) && missing(effects)) {
    baseline <- sim.object$baseline
    processes <- sim.object$processes
    effects <- sim.object$effects
  }

  covariate_nodes <- lapply(baseline, sim_covariate)

  process_nodes <- lapply(processes, function(process) {
    type <- switch(
      process[["type"]],
      censoring = "censoring",
      terminal = "terminal",
      "transient"
    )
    limit <- if (identical(process[["type"]], "one.jump")) 1 else Inf
    sim_process(
      type = type,
      eta = process[["eta"]],
      nu = process[["nu"]],
      limit = limit
    )
  })

  effect_nodes <- lapply(effects, function(effect) {
    sim_effect(effect[[1]], effect[[2]], as.numeric(effect[[3]]))
  })

  graph <- do.call(
    sim_graph,
    c(covariate_nodes, process_nodes, list(effects = effect_nodes))
  )

  intervene <- c(baseline.intervention, alpha.intervention)

  if (browse) {
    browser()
  }

  run_sim_graph(
    graph,
    n = n,
    intervene = intervene,
    cens = cens,
    max_cens = Inf,
    max_events = 50,
    lower = 1e-25,
    upper = 1e8
  )
}
