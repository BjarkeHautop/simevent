#' Simulate Event History Data from Parameters Fitted to Observed Data
#'
#' `sim.from.data` simulates new multistate event history data using
#' process/baseline parameters previously estimated from observed data (e.g.
#' Weibull and Cox parameters extracted from \code{coxph} fits, as
#' \code{\link{simEventCox}} does with its \code{cox_fits} argument), via
#' \code{\link{simEventData}}.
#'
#' Unlike \code{\link{sim.generic}}, which takes user-specified effects
#' directly, \code{sim.from.data} is meant to be fed parameters estimated
#' from real data, so that the simulated data mimics an observed dataset's
#' distribution (optionally under an intervention via
#' \code{alpha.intervention}/\code{baseline.intervention}). See
#' \code{vignette("sim-generic", package = "simevent")} for a worked example
#' of building \code{sim.parameters} by hand from \code{coxph}/\code{basehaz}
#' fits.
#'
#' @param n Integer. Number of individuals to simulate. Default 500.
#' @param sim.parameters Named list of fitted simulation parameters, with one
#'   entry per process plus a \code{baseline.summary} entry and a
#'   \code{model.structure} entry:
#'   \itemize{
#'     \item Each process entry (named after the process) is a list with
#'       \code{weibull.parameters} (a named numeric vector with entries whose
#'       names start with \code{"eta"} and \code{"nu"}) and
#'       \code{cox.parameters} (a named numeric vector of Cox coefficients,
#'       named after baseline covariates, other processes, or
#'       \code{"<covariate>=<level>"}-style names for categorical baseline
#'       effects).
#'     \item \code{baseline.summary} is a named list, one entry per baseline
#'       covariate, each a list with a \code{type} (\code{"numeric"} or a
#'       factor/character class) and either \code{mean}/\code{sd} (for a
#'       continuous covariate), \code{mean} alone (for a 0/1 covariate,
#'       interpreted as a Bernoulli probability), or \code{proportions} (a
#'       named list/table of category probabilities).
#'     \item \code{model.structure} is a list with \code{process.names},
#'       \code{process.deltas} (numeric \code{delta} value for each
#'       process), and \code{process.types} (\code{"terminal"},
#'       \code{"one.jump"}, or any other value for a recurrent process, one
#'       per process), plus \code{cens.process.id} (the index into
#'       \code{process.names} of the censoring process).
#'   }
#' @param cens Numeric. At-risk indicator scaling for the censoring process.
#'   Default 1.
#' @param alpha.intervention Named list of multiplicative interventions on
#'   process intensities (\code{eta}), keyed by process name.
#' @param baseline.intervention Named list of interventions that fix a
#'   baseline covariate to a constant value, keyed by covariate name.
#' @param browse Logical. If \code{TRUE}, drop into \code{browser()} before
#'   simulating. Default \code{FALSE}.
#' @param verbose Logical. If \code{TRUE}, print the resolved \code{eta}/
#'   \code{nu}/\code{beta} parameters. Default \code{FALSE}.
#'
#' @return A \code{data.table} of simulated event history data with columns
#'   \code{id}, \code{time}, \code{delta}, the baseline covariates, and one
#'   column per non-terminal process.
#'
#' @export
sim.from.data <- function(
  n = 500,
  sim.parameters,
  cens = 1,
  alpha.intervention = list(),
  baseline.intervention = list(),
  browse = FALSE,
  verbose = FALSE
) {
  processes <- names(sim.parameters)[
    names(sim.parameters) != "baseline.summary"
  ]

  baseline.vars <- unique(names(sim.parameters$baseline.summary))

  add_cov <- lapply(baseline.vars, function(x) {
    svar <- sim.parameters$baseline.summary[[x]]
    type <- svar$type
    if (type == "numeric") {
      if (
        (svar$type == "numeric" &&
          svar$min %in% c(0, -1) &&
          svar$max %in% c(1, 0) &&
          length(unique(c(svar$min, svar$max))) == 2)
      ) {
        p <- svar$mean
        return(function(N) stats::rbinom(N, 1, p))
      } else {
        mu <- svar$mean
        sd <- svar$sd
        return(function(N) stats::rnorm(N, mean = mu, sd = sd))
      }
    } else {
      probs <- unlist(svar$proportions)
      vals <- seq_along(names(probs))
      return(function(N) sample(vals, N, replace = TRUE, prob = probs))
    }
  })

  names(add_cov) <- baseline.vars

  process.names <- sim.parameters$model.structure$process.names
  process.deltas <- sim.parameters$model.structure$process.deltas

  which.cens <- process.names[sim.parameters$model.structure$cens.process.id]
  which.terminal <- setdiff(
    process.names[sim.parameters$model.structure$process.types == "terminal"],
    which.cens
  )
  which.one.jump <- setdiff(
    process.names[sim.parameters$model.structure$process.types == "one.jump"],
    c(which.terminal, which.cens)
  )

  process.order <- process.names[order(process.deltas)]

  eta <- as.numeric(sapply(sim.parameters[process.order], function(sim.param) {
    sim.param[["weibull.parameters"]][
      substr(names(sim.param[["weibull.parameters"]]), 1, 3) == "eta"
    ]
  }))
  nu <- as.numeric(sapply(sim.parameters[process.order], function(sim.param) {
    sim.param[["weibull.parameters"]][
      substr(names(sim.param[["weibull.parameters"]]), 1, 2) == "nu"
    ]
  }))

  if (length(baseline.intervention) > 0) {
    for (bname in names(baseline.intervention)) {
      add_cov[[bname]] <- function(N) rep(baseline.intervention[[bname]], N)
    }
  }

  if (length(alpha.intervention) > 0) {
    for (alphaname in names(alpha.intervention)) {
      eta[process.order == alphaname] <-
        alpha.intervention[[alphaname]] * eta[process.order == alphaname]
    }
  }

  if (verbose) {
    print(paste0("eta = ", eta))
    print(paste0("nu = ", nu))
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

  override_beta <- NULL

  for (proc in process.order) {
    cp <- sim.parameters[[proc]]$cox.parameters

    for (v in names(cp)) {
      if (v %in% c(baseline.vars, process.order)) {
        beta[v, proc] <- cp[v]
      } else {
        bvar <- baseline.vars[sapply(baseline.vars, function(baseline.var) {
          length(grep(baseline.var, v, value = TRUE)) > 0
        })]
        bvalue <- gsub(bvar, "", v)

        svar <- sim.parameters$baseline.summary[[bvar]]
        probs <- unlist(svar$proportions)
        vals <- seq_along(names(probs))

        bval <- vals[names(probs) == bvalue][1]

        out_vec <- cp[v]
        names(out_vec) <- paste0(
          "N",
          match(proc, process.order) - 1
        )
        expr <- paste0("(", bvar, "==", bval, ")")
        if (is.null(override_beta[[expr]])) {
          override_beta[[expr]] <- out_vec
        } else {
          override_beta[[expr]] <- c(override_beta[[expr]], out_vec)
        }
      }
    }
  }

  if (verbose) {
    print(beta)
  }

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
    lower = 1e-45,
    upper = 1e10,
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
