#' Summarise a `sim_graph()`
#'
#' Tabulates a [sim_graph()]'s covariates, processes and effects.
#'
#' @param object A [sim_graph()].
#' @param x A `summary.sim_graph` object, as returned by `summary()`.
#' @param ... Not used.
#'
#' @return A list of three `data.frame`s: `covariates`, `processes` and
#'   `effects`.
#' @seealso [sim_graph()]
#' @examples
#' graph <- sim_graph(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   relapse = sim_process("transient", eta = 0.2, nu = 1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.03),
#'     sim_effect("relapse", "death", coef = 1)
#'   )
#' )
#' graph
#' summary(graph)
#' @export
summary.sim_graph <- function(object, ...) {
  shown <- object$covariates[!.sim_graph_hidden(names(object$covariates))]
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
    class = "summary.sim_graph"
  )
}

#' @rdname summary.sim_graph
#' @export
print.summary.sim_graph <- function(x, ...) {
  cat("<sim_graph> covariates\n")
  print(x$covariates, row.names = FALSE)
  cat("\n<sim_graph> processes\n")
  print(x$processes, row.names = FALSE)
  cat("\n<sim_graph> effects\n")
  print(x$effects, row.names = FALSE)
  invisible(x)
}
