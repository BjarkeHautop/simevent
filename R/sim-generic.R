#' Simulate Event History Data from a Generic Process Specification
#'
#' `sim.generic` simulates multistate event history data from a set of
#' user-specified baseline covariates, event processes (with Weibull
#' intensities and Cox-type effects), and their effects on one another, by
#' translating the specification into a call to \code{\link{simEventData}}.
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

  baseline.vars <- names(baseline)

  add_cov <- copy(baseline)

  process.names <- names(processes)

  which.cens <- process.names[sapply(processes, function(process) {
    process[["type"]] == "censoring"
  })]
  which.terminal <- process.names[sapply(processes, function(process) {
    process[["type"]] == "terminal"
  })]
  which.one.jump <- setdiff(
    process.names[sapply(processes, function(process) {
      process[["type"]] == "one.jump"
    })],
    c(which.terminal, which.cens)
  )

  process.order <- c(
    which.cens,
    which.terminal,
    setdiff(process.names, c(which.cens, which.terminal))
  )

  eta <- sapply(processes[process.order], function(process) process[["eta"]])
  nu <- sapply(processes[process.order], function(process) process[["nu"]])

  if (length(baseline.intervention) > 0) {
    for (bname in names(baseline.intervention)) {
      add_cov[[bname]] <- function(N) rep(baseline.intervention[[bname]], N)
    }
  }

  if (length(alpha.intervention) > 0) {
    for (alphaname in names(alpha.intervention)) {
      eta[names(processes[process.order]) == alphaname] <-
        alpha.intervention[[alphaname]] *
        eta[names(processes[process.order]) == alphaname]
    }
  }

  at_risk <- function(events) {
    out <- numeric(length(process.order))

    names(out) <- process.order

    ## censoring
    out[process.order %in% which.cens] <- cens

    ## terminal events
    out[process.order %in% which.terminal] <- 1

    ## one jump
    for (one.jump in which.one.jump) {
      idx <- which(process.order == one.jump)
      out[idx] <- as.numeric(events[idx] == 0)
    }

    ## recurrent
    out[setdiff(
      process.order,
      c(which.cens, which.terminal, which.one.jump)
    )] <- 1

    return(out)
  }

  if (!("A0" %in% baseline.vars)) {
    add_A0 <- 1
  } else {
    add_A0 <- 0
  }

  if (!("L0" %in% baseline.vars)) {
    add_L0 <- 1
  } else {
    add_L0 <- 0
  }

  other.baseline.vars <- setdiff(baseline.vars, c("L0", "A0"))

  beta <- matrix(
    0,
    nrow = length(process.order) + length(other.baseline.vars) + 2,
    ncol = length(process.order)
  )

  # simEventData() always renames beta's rows to L0, A0, ... positionally
  # (to match its internal simmatrix), so this order must be fixed
  # regardless of whether L0/A0 were user-supplied or auto-added.
  rownames(beta) <- c("L0", "A0", other.baseline.vars, process.order)
  colnames(beta) <- process.order

  for (effect in effects) {
    beta[effect[1], effect[2]] <- as.numeric(effect[3])
  }

  # simEventData() matches beta's rows by name when beta has rownames, but
  # only against its own fixed L0/A0/add_cov/N0/N1/... names, which our
  # descriptive process/baseline names above aren't drawn from. Drop the
  # rownames so it falls back to positional matching instead, which the
  # row order set above (L0, A0, other baseline vars, process order) already
  # satisfies.
  rownames(beta) <- NULL

  override_beta <- NULL

  if (browse) {
    browser()
  }

  term.processes <- c(which.cens, which.terminal)
  term.deltas <- match(term.processes, process.order) - 1L

  non.term.processes <- setdiff(process.order, term.processes)
  non.term.deltas <- match(non.term.processes, process.order) - 1L

  data <- simEventData(
    N = n,
    beta = beta,
    eta = eta,
    nu = nu,
    max_cens = Inf,
    max_events = 50,
    at_risk = at_risk,
    lower = 1e-25,
    upper = 1e8,
    term_deltas = term.deltas,
    gen_L0 = add_cov[["L0"]],
    gen_A0 = {
      if ("A0" %in% names(add_cov)) function(N, L0) add_cov[["A0"]](N) else NULL
    },
    add_cov = add_cov[!(names(add_cov) %in% c("A0", "L0"))],
    override_beta = override_beta
  )

  if (add_L0) {
    data[["L0"]] <- NULL
  }

  if (add_A0) {
    data[["A0"]] <- NULL
  }

  for (jj in term.deltas) {
    data[[paste0("N", jj)]] <- NULL
  }

  if (length(non.term.processes) > 0) {
    setnames(data, paste0("N", non.term.deltas), non.term.processes)
  }

  setnames(data, c("Delta", "Time", "ID"), c("delta", "time", "id"))

  return(data)
}
