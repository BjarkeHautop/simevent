#' Risk of, or Time Lost to, an Event by a Time Horizon
#'
#' With \eqn{T} the time of an individual's first `process` event (\eqn{\infty}
#' if none):
#' \describe{
#'   \item{`"risk"`}{\eqn{P(T \le \tau)}.}
#'   \item{`"time_lost"`}{\eqn{E[\tau - \min(T, \tau)]}, the restricted mean
#'     time lost.}
#' }
#' Compare runs with and without [sim_event_graph()]'s `intervene` to
#' estimate an intervention's effect. Estimates are biased if anyone is
#' censored before `tau` (a warning is given); simulate with `cens = 0` to
#' avoid this.
#'
#' @param data Output of [sim_event_graph()].
#' @param graph The [sim_graph()] `data` was simulated from.
#' @param process Character vector. Process(es) to summarise.
#' @param tau Numeric. Time horizon.
#' @param type `"risk"` (default) or `"time_lost"`.
#' @param by Character vector. Columns of `data` to summarise within.
#'
#' @return A `data.table` with the `by` columns, `process`, and the estimate
#'   (column named after `type`).
#' @seealso [sim_event_graph()]
#' @examples
#' graph <- sim_graph(
#'   A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   disease = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
#'   effects = list(
#'     sim_effect("A0", "death", coef = 0.5),
#'     sim_effect("disease", "death", coef = 1)
#'   )
#' )
#'
#' # Halve the disease hazard and compare against no intervention:
#' set.seed(1)
#' observed <- sim_event_graph(graph, n = 2000)
#' intervened <- sim_event_graph(graph, n = 2000, intervene = list(disease = 0.5))
#'
#' event_risk(observed, graph, c("death", "disease"), tau = 5)
#' event_risk(intervened, graph, c("death", "disease"), tau = 5)
#'
#' # Years lost before tau, separately for A0 = 0 and A0 = 1:
#' event_risk(intervened, graph, "death", tau = 5, type = "time_lost", by = "A0")
#' @export
event_risk <- function(
  data,
  graph,
  process,
  tau,
  type = c("risk", "time_lost"),
  by = character(0)
) {
  id <- time <- event <- first_time <- NULL
  checkmate::assert_data_frame(data)
  checkmate::assert_class(graph, "sim_graph")
  checkmate::assert_subset(c("id", "time", "event"), names(data))
  checkmate::assert_character(process, min.len = 1, unique = TRUE)
  checkmate::assert_subset(process, names(graph$processes))
  checkmate::assert_number(tau, lower = 0, finite = TRUE)
  type <- match.arg(type)
  checkmate::assert_character(by, unique = TRUE)
  checkmate::assert_subset(by, setdiff(names(data), c("id", "time", "event")))

  data <- data.table::as.data.table(data)
  types <- vapply(graph$processes, `[[`, character(1), "type")
  censoring_events <- c(names(types)[types == "censoring"], "max_cens")
  if (any(data$event %in% censoring_events & data$time < tau)) {
    warning(
      "Some individuals are censored before tau, so event_risk()'s ",
      "empirical estimates are biased. Simulate with cens = 0 for an ",
      "uncensored estimate."
    )
  }

  # One row per individual (with its by-columns, constant within id); by
  # columns are baseline covariates, so the first row's value is the value.
  individuals <- unique(data[, c("id", by), with = FALSE], by = "id")

  res <- lapply(process, function(proc) {
    first <- data[
      event == proc,
      list(first_time = min(time)),
      by = id
    ]
    ind <- merge(individuals, first, by = "id", all.x = TRUE)
    ind[is.na(first_time), first_time := Inf]
    value <- if (type == "risk") {
      quote(mean(first_time <= tau))
    } else {
      quote(mean(tau - pmin(first_time, tau)))
    }
    out <- ind[, list(estimate = eval(value)), keyby = by]
    out[, process := proc]
    out
  })

  res <- data.table::rbindlist(res)
  data.table::setcolorder(res, c(by, "process", "estimate"))
  data.table::setnames(res, "estimate", type)
  res[]
}
