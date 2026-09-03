# Internal helper shared by alphaSim() and intEffectAlpha(): simulates data
# from the requested setting with the shape parameter eta of the relevant
# process multiplied by alpha.

.simAlphaData <- function(setting, N, eta, nu, alpha, cens, allow_statin, ...) {
  if (setting == "Disease") {
    if (length(eta) != 3 || length(nu) != 3) {
      stop("eta and nu must be of length 3 in the Disease setting")
    }
    return(simDisease(
      N = N,
      eta = c(eta[1:2], eta[3] * alpha),
      cens = cens,
      ...
    ))
  }

  if (setting == "Drop In") {
    if (length(eta) != 4 || length(nu) != 4) {
      stop("eta and nu must be of length 4 in the Drop In setting")
    }
    return(simDropIn(
      N = N,
      eta = c(eta[1:2], eta[3] * alpha, eta[4]),
      nu = nu,
      cens = cens,
      ...
    ))
  }

  if (setting == "Treatment") {
    if (length(eta) != 4 || length(nu) != 4) {
      stop("eta and nu must be of length 4 in the Treatment setting")
    }
    return(simTreatment(
      N = N,
      eta = c(eta[1:2], eta[3] * alpha, eta[4]),
      cens = cens,
      nu = nu,
      ...
    ))
  }

  if (allow_statin && setting == "Statin") {
    if (length(eta) != 12 || length(nu) != 12) {
      stop("eta and nu must be of length 12 in the Statin setting")
    }
    return(simStatinData(
      N = N,
      eta = c(eta[1:3], eta[4] * alpha, eta[5:12]),
      nu = nu,
      ...
    ))
  }

  if (allow_statin) {
    stop("Setting must be either Disease, Drop In, Treatment or Statin")
  } else {
    stop("Setting must be either Disease, Drop In or Treatment")
  }
}
