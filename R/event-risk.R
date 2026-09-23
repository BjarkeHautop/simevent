#' Risk of, or Time Lost to, an Event by a Time Horizon
#'
#' `event_risk` summarises [sim_event_graph()] output by the proportion of
#' individuals who have experienced a process by time `tau` (the absolute
#' risk / cumulative incidence), or by the expected time lost to it before
#' `tau`. Combined with [sim_event_graph()]'s `intervene` argument, this is
#' how to estimate the effect of an intervention: simulate once with and
#' once without the intervention, and compare the two summaries.
#'
#' For each individual, only the *first* event of `process` counts (relevant
#' for a `"transient"` process that can fire more than once). With \eqn{T}
#' that first event time (infinite if it never occurs):
#' \describe{
#'   \item{`"risk"`}{\eqn{P(T \le \tau)}.}
#'   \item{`"time_lost"`}{\eqn{E[\tau - \min(T, \tau)]}, the restricted mean
#'     time lost, i.e. the area under the risk curve on \eqn{[0, \tau]}.}
#' }
#' Both are plain empirical averages over individuals, which are only
#' unbiased when no one is censored before `tau`. Simulate with `cens = 0`
#' (or a graph without a `"censoring"` process) to get the uncensored
#' counterfactual; a warning is given otherwise.
#'
#' @param data A `data.table` as returned by [sim_event_graph()].
#' @param graph The [sim_graph()] `data` was simulated from, used to map
#'   process names to `data`'s `delta` codes.
#' @param process Character vector. Name(s) of processes in `graph` to
#'   summarise, each separately.
#' @param tau Numeric scalar. Time horizon.
#' @param type Either `"risk"` (default) or `"time_lost"`.
#' @param by Character vector. Names of `data` columns (typically baseline
#'   covariates) to summarise within levels of. Default `character(0)` (all
#'   individuals together).
#'
#' @return A `data.table` with the `by` columns, `process`, and a column
#'   named after `type` holding the estimate.
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
  id <- time <- delta <- first_time <- NULL
  checkmate::assert_data_frame(data)
  checkmate::assert_class(graph, "sim_graph")
  checkmate::assert_subset(c("id", "time", "delta"), names(data))
  checkmate::assert_character(process, min.len = 1, unique = TRUE)
  checkmate::assert_subset(process, names(graph$processes))
  checkmate::assert_number(tau, lower = 0, finite = TRUE)
  type <- match.arg(type)
  checkmate::assert_character(by, unique = TRUE)
  checkmate::assert_subset(by, setdiff(names(data), c("id", "time", "delta")))

  data <- data.table::as.data.table(data)
  process_order <- .sim_graph_process_order(graph)
  delta_codes <- stats::setNames(seq_along(process_order) - 1L, process_order)

  types <- vapply(graph$processes, `[[`, character(1), "type")
  cens_codes <- delta_codes[names(types)[types == "censoring"]]
  if (any(data$delta %in% cens_codes & data$time < tau)) {
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
      delta == delta_codes[[proc]],
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
