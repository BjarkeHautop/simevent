#' Estimate Effect of Intervention: Modifying Eta Parameter of Process
#'
#' Simulates data from the Disease, Drop In, or Treatment setting under an intervention
#' where the shape parameter \eqn{\eta} of the disease, drop-in, or treatment process
#' (respectively) is multiplied by \code{alpha}. It computes the proportion of individuals
#' who experience death, and the proportion who experience disease/drop-in/treatment, by a
#' specified time \eqn{\tau} in the group \code{A0 = a0} (except in the Treatment setting,
#' where all individuals are used), optionally returning years lost instead of proportions.
#' The function can also plot a sample of the simulated (intervened) event data.
#'
#' @param N Integer. Number of individuals to simulate. Default is 10,000.
#' @param setting Character string. Must be either "Disease", "Drop In" or "Treatment". Depending on the simulation setting.
#' @param eta Numeric vector. Shape parameters for Weibull hazards: length 3 for setting "Disease", length 4 for "Drop In" or "Treatment" (default \code{rep(0.1, 4)}).
#' @param nu Numeric vector. Scale parameters for Weibull hazards: length 3 for setting "Disease", length 4 for "Drop In" or "Treatment" (default \code{rep(1.1, 4)}).
#' @param alpha Numeric scalar. Multiplicative factor applied to the shape parameter \eqn{\eta} of the relevant process.
#' @param tau Numeric scalar. Time horizon at which proportions are computed.
#' @param a0 Binary (0/1). Specifies the group for comparison. Only relevant in setting "Drop In" and "Disease".
#' @param years_lost Logical. If \code{TRUE}, computes years lost instead of proportions.
#' @param plot Logical. If \code{TRUE}, plots a sample of the simulated event data.
#' @param lower Numeric scalar. Lower bound for root-finding in hazard inversion (default 1e-30).
#' @param upper Numeric scalar. Upper bound for root-finding in hazard inversion (default 200).
#' @param cens Binary scalar. Indicates whether individuals are at risk of censoring (default \code{0}).
#' @param ... Additional arguments passed to respectively simDisease, simTreatment and simDropIn.
#'
#' @return A list with two components:
#' \describe{
#'   \item{\code{effect_2}}{Proportion (or years lost) of individuals experiencing disease/drop-in/treatment by time \eqn{\tau}, under intervention.}
#'   \item{\code{effect_death}}{Proportion (or years lost) of individuals who died by time \eqn{\tau}, under intervention.}
#' }
#' @export
#'
#' @examples
#' intEffectAlpha(N = 1000, alpha = 0.7, tau = 5, years_lost = FALSE, a0 = 1, setting = "Drop In")
intEffectAlpha <- function(
  N = 1e4,
  setting = "Disease",
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  alpha = 0.5,
  tau = 5,
  a0 = 1,
  years_lost = FALSE,
  plot = TRUE,
  lower = 10^(-30),
  upper = 200,
  cens = 0,
  ...
) {
  Delta <- Time <- A0 <- NULL

  # Generate large data set under the intervened intensity
  data <- .simAlphaData(
    setting = setting,
    N = N,
    eta = eta,
    nu = nu,
    alpha = alpha,
    cens = cens,
    allow_statin = FALSE,
    ...
  )

  if (plot) {
    plotEventData(data[1:250], title = "Under Intervention")
  }

  # Proportion of subjects dying before some time $\tau$
  if (setting == "Treatment") {
    prop_G1 <- data[Delta == 1, mean(Delta == 1 & Time < tau)]
  } else {
    prop_G1 <- data[A0 == a0 & Delta == 1, mean(Delta == 1 & Time < tau)]
  }

  # Proportion of subjects experiencing Treatment/Drop In/Disease
  if (setting == "Treatment") {
    prop_G1_2 <- mean(data[, any(Delta == 2 & Time < tau)[1], by = "ID"][[2]])
  } else {
    prop_G1_2 <- mean(data[
      A0 == a0,
      any(Delta == 2 & Time < tau)[1],
      by = "ID"
    ][[2]])
  }

  if (years_lost) {
    tgrid <- seq(0, tau, length = 100)
    if (setting == "Treatment") {
      prop_G1 <- sum(
        diff(tgrid)[1] *
          sapply(tgrid[-1], function(t) {
            data[Delta == 1, mean(Delta == 1 & Time <= t)]
          })
      )
      prop_G1_2 <- sum(
        diff(tgrid)[1] *
          sapply(tgrid[-1], function(t) {
            mean(data[, any(Delta == 2 & Time <= t)[1], by = "ID"][[2]])
          })
      ) # with intervention
    } else {
      prop_G1 <- sum(
        diff(tgrid)[1] *
          sapply(tgrid[-1], function(t) {
            data[A0 == a0 & Delta == 1, mean(Delta == 1 & Time <= t)]
          })
      )

      prop_G1_2 <- sum(
        diff(tgrid)[1] *
          sapply(tgrid[-1], function(t) {
            mean(data[A0 == a0, any(Delta == 2 & Time <= t)[1], by = "ID"][[2]])
          })
      )
    }
  }

  return(list(effect_2 = prop_G1_2, effect_death = prop_G1))
}
