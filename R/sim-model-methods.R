#' Summarise a `sim_model()`
#'
#' Tabulates a [sim_model()]'s covariates, processes and effects.
#'
#' @param object A [sim_model()].
#' @param x A `summary.sim_model` object, as returned by `summary()`.
#' @param ... Not used.
#'
#' @return A list of three `data.frame`s: `covariates`, `processes` and
#'   `effects`.
#' @seealso [sim_model()]
#' @examples
#' model <- sim_model(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   relapse = sim_process("transient", eta = 0.2, nu = 1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.03),
#'     sim_effect("relapse", "death", coef = 1)
#'   )
#' )
#' model
#' summary(model)
#' @export
summary.sim_model <- function(object, ...) {
  shown <- object$covariates[!.sim_hidden(names(object$covariates))]
  covariates <- data.frame(
    name = names(shown),
    kind = vapply(
      shown,
      function(node) {
        if (inherits(node, "sim_derived")) "derived" else "baseline"
      },
      character(1)
    ),
    row.names = NULL
  )
  processes <- data.frame(
    name = names(object$processes),
    type = vapply(object$processes, `[[`, character(1), "type"),
    baseline = vapply(
      object$processes,
      function(proc) if (is.null(proc$cumhaz)) "weibull" else "cumhaz",
      character(1)
    ),
    eta = vapply(object$processes, `[[`, numeric(1), "eta"),
    nu = vapply(object$processes, `[[`, numeric(1), "nu"),
    limit = vapply(object$processes, `[[`, numeric(1), "limit"),
    row.names = NULL
  )
  effects <- data.frame(
    from = vapply(object$effects, `[[`, character(1), "from"),
    to = vapply(object$effects, `[[`, character(1), "to"),
    coef = vapply(object$effects, `[[`, numeric(1), "coef"),
    row.names = NULL
  )
  structure(
    list(covariates = covariates, processes = processes, effects = effects),
    class = "summary.sim_model"
  )
}

#' @rdname summary.sim_model
#' @export
print.summary.sim_model <- function(x, ...) {
  cat("<sim_model> covariates\n")
  print(x$covariates, row.names = FALSE)
  cat("\n<sim_model> processes\n")
  print(x$processes, row.names = FALSE)
  cat("\n<sim_model> effects\n")
  print(x$effects, row.names = FALSE)
  invisible(x)
}
