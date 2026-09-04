#' Simulation and Estimation with Modified Shape Parameter
#'
#' This function simulates event history data from the Disease, Treatment, Drop In, or Statin
#' setting (see \code{simDisease}, \code{simTreatment}, \code{simDropIn}, and \code{simStatinData}).
#' The shape parameter \eqn{\eta} of the disease/treatment/drop-in/MACE process is multiplied by
#' \code{alpha}. The function either
#' * returns the proportion of individuals who experience death and the proportion of individuals who experience disease/drop in/treatment
#' by a specified time \eqn{\tau} (in group \code{A0 = a0} for drop in and disease).
#' * returns number of years lost before \eqn{\tau} of death and disease/drop in/treatment
#' * returns simulated data.
#' One can specify all the same parameters as in the functions \code{simDisease}, \code{simTreatment} and \code{simDropIn}.
#'
#' @param N Integer. Number of individuals to simulate. Default is 10,000.
#' @param alpha Numeric scalar. Multiplicative factor applied to the disease process shape parameter \eqn{\eta}.
#' @param tau Numeric scalar. Time horizon at which proportions are computed.
#' @param years_lost Logical. If \code{TRUE}, computes years lost instead of proportions.
#' @param a0 Binary (0/1). Specifies the group for comparison in setting Drop In and Disease.
#' @param eta Numeric vector. Shape parameters for Weibull hazards. Length of the vector should
#' match number of events: 3 for the Disease setting, 4 for the Drop In or Treatment setting,
#' 12 for the Statin setting (default \code{rep(0.1, 4)}).
#' @param nu Numeric vector. Scale parameters for Weibull hazards. Length of the vector should
#' match number of events: 3 for the Disease setting, 4 for the Drop In or Treatment setting,
#' 12 for the Statin setting (default \code{rep(1.1, 4)}).
#' @param cens Binary scalar. Indicates whether individuals are at risk of censoring (default \code{0}).
#' @param setting Character string. Must be "Disease", "Drop In", "Treatment", or "Statin". Depending on the simulation setting.
#' @param return_data Logical. If \code{TRUE} the simulated data is returned.
#' @param ... Additional arguments passed to respectively simDisease, simTreatment and simDropIn.
#'
#' @return A list with two components:
#' \describe{
#'   \item{\code{effectDeath}}{Proportion (or years lost) of individuals who died by time \eqn{\tau}, under intervention.}
#'   \item{\code{effectSetting}}{Proportion (or years lost) of individuals experiencing disease/drop-in/treatment/MACE by time \eqn{\tau}, under intervention.}
#' }
#' Or the simulated data, if \code{return_data = TRUE}.
#' @export
#'
#' @examples
#' alphaSim(N = 100, eta = rep(0.1,3), nu = rep(1.1,3), alpha = 0.5, setting = "Disease")
#' alphaSim(N = 100, setting = "Drop In", beta_A0_Z = 1)
alphaSim <- function(
  N = 1e4,
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  alpha = 0.5,
  tau = 5,
  a0 = 1,
  years_lost = FALSE,
  setting = "Disease",
  return_data = FALSE,
  cens = 0,
  ...
) {
  Delta <- Time <- A0 <- tmp <- V1 <- NULL

  # Generate large data set under the intervened intensity
  data <- .simAlphaData(
    setting = setting,
    N = N,
    eta = eta,
    nu = nu,
    alpha = alpha,
    cens = cens,
    allow_statin = TRUE,
    ...
  )

  if (return_data) {
    return(data)
  }

  # Proportion of subjects dying before some time $\tau$
  if (setting == "Treatment") {
    prop_D <- data[Delta == 1, mean(Delta == 1 & Time < tau)]
  } else if (setting == "Statin") {
    prop_D <- mean(data[, any(Delta == 1 & Time < tau)[1], by = "ID"][[2]])
  } else {
    prop_D <- data[A0 == a0 & Delta == 1, mean(Delta == 1 & Time < tau)]
  }

  # Proportion of subjects experiencing Treatment/Drop In/Disease/MACE
  if (setting == "Treatment") {
    prop2 <- mean(data[, any(Delta == 2 & Time < tau)[1], by = "ID"][[2]])
  }
  if (setting == "Drop In") {
    prop2 <- mean(data[A0 == a0, any(Delta == 2 & Time < tau)[1], by = "ID"][[
      2
    ]])
  }
  if (setting == "Disease") {
    prop2 <- mean(data[A0 == a0, any(Delta == 2 & Time < tau)[1], by = "ID"][[
      2
    ]])
  }
  if (setting == "Statin") {
    prop2 <- mean(data[, any(Delta == 2 & Time < tau)[1], by = "ID"][[2]])
  }

  if (years_lost) {
    data[, tmp := cumsum((Delta == 1) * (tau - pmin(tau, Time))), by = "ID"]
    prop_D <- data[, tmp[.N], by = "ID"][, mean(V1)]
    data[, tmp := cumsum((Delta == 2) * (tau - pmin(tau, Time))), by = "ID"]
    prop2 <- data[, tmp[.N], by = "ID"][, mean(V1)]
  }

  return(list(effectDeath = prop_D, effectSetting = prop2))
}
