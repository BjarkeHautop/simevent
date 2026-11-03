#' Risk of, or Time Lost to, an Event by a Time Horizon
#'
#' With \eqn{T} the time of an individual's first `process` event (\eqn{\infty}
#' if none):
#' \describe{
#'   \item{`"risk"`}{\eqn{P(T \le \tau)}.}
#'   \item{`"time_lost"`}{\eqn{E[\tau - \min(T, \tau)]}, the restricted mean
#'     time lost.}
#' }
#' Compare runs with and without [sim_events()]'s `intervene` to
#' estimate an intervention's effect. Estimates are biased if anyone is
#' censored before `tau` (a warning is given); simulate with `cens = 0` to
#' avoid this.
#'
#' @param data Output of [sim_events()].
#' @param model The [sim_model()] `data` was simulated from.
#' @param process Character vector. Process(es) to summarise.
#' @param tau Numeric. Time horizon.
#' @param type `"risk"` (default) or `"time_lost"`.
#' @param by Character vector. Baseline columns of `data` to summarise
#'   within. A [sim_mark()] changes over follow-up, so group by its baseline
#'   value `<mark>_0` instead; transient process counts can't be used.
#'
#' @return A `data.table` with the `by` columns, `process`, and the estimate
#'   (column named after `type`).
#' @seealso [sim_events()]
#' @examples
#' model <- sim_model(
#'   A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   disease = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
#'   effects = list(
#'     sim_effect(death ~ A0, coef = 0.5),
#'     sim_effect(death ~ disease, coef = 1)
#'   )
#' )
#'
#' # Halve the disease hazard and compare against no intervention:
#' set.seed(1)
#' observed <- sim_events(model, n = 2000)
#' intervened <- sim_events(model, n = 2000, intervene = list(disease = 0.5))
#'
#' event_risk(observed, model, c("death", "disease"), tau = 5)
#' event_risk(intervened, model, c("death", "disease"), tau = 5)
#'
#' # Years lost before tau, separately for A0 = 0 and A0 = 1:
#' event_risk(intervened, model, "death", tau = 5, type = "time_lost", by = "A0")
#'
#' # Group by a sim_mark()'s baseline value, <mark>_0 (the mark itself changes
#' # over follow-up, so by = "L" is an error):
#' draw_l <- function(N) rbinom(N, 1, 0.5)
#' model_l <- sim_model(
#'   L = sim_mark(draw_l, "visit", draw_l),
#'   visit = sim_process("transient", eta = 0.5, nu = 1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(sim_effect(death ~ L, coef = 1))
#' )
#' data_l <- sim_events(model_l, n = 2000)
#' event_risk(data_l, model_l, "death", tau = 5, by = "L_0")
#' @export
event_risk <- function(
  data,
  model,
  process,
  tau,
  type = c("risk", "time_lost"),
  by = character(0)
) {
  id <- time <- event <- first_time <- NULL
  checkmate::assert_data_frame(data)
  checkmate::assert_class(model, "sim_model")
  checkmate::assert_subset(c("id", "time", "event"), names(data))
  checkmate::assert_character(process, min.len = 1, unique = TRUE)
  checkmate::assert_subset(process, names(model$processes))
  checkmate::assert_number(tau, lower = 0, finite = TRUE)
  type <- match.arg(type)
  checkmate::assert_character(by, unique = TRUE)
  checkmate::assert_subset(by, setdiff(names(data), c("id", "time", "event")))
  is_mark <- vapply(model$covariates, inherits, logical(1), "sim_mark")
  marks_in_by <- intersect(by, names(model$covariates)[is_mark])
  if (length(marks_in_by) > 0) {
    stop(
      "by must be baseline columns, but ",
      paste0("'", marks_in_by, "'", collapse = ", "),
      " is a sim_mark() that changes over follow-up. Use its baseline value ",
      paste0("'", marks_in_by, "_0'", collapse = ", "),
      " instead."
    )
  }
  counts_in_by <- intersect(by, names(model$processes))
  if (length(counts_in_by) > 0) {
    stop(
      "by must be baseline columns, but ",
      paste0("'", counts_in_by, "'", collapse = ", "),
      " is a process event count that changes over follow-up."
    )
  }

  data <- data.table::as.data.table(data)
  types <- vapply(model$processes, `[[`, character(1), "type")
  censoring_events <- c(names(types)[types == "censoring"], "max_cens")
  if (any(data$event %in% censoring_events & data$time < tau)) {
    warning(
      "Some individuals are censored before tau, so event_risk()'s ",
      "empirical estimates are biased. Simulate with cens = 0 for an ",
      "uncensored estimate."
    )
  }

  # One row per individual (with its by-columns); by columns are baseline
  # covariates (marks and counts are rejected above), so constant within id.
  individuals <- unique(data[, c("id", by), with = FALSE], by = "id")

  estimate <- if (type == "risk") {
    function(first_time) mean(first_time <= tau)
  } else {
    function(first_time) mean(tau - pmin(first_time, tau))
  }
  res <- lapply(process, function(proc) {
    first <- data[
      event == proc,
      list(first_time = min(time)),
      by = id
    ]
    ind <- merge(individuals, first, by = "id", all.x = TRUE)
    ind[is.na(first_time), first_time := Inf]
    out <- ind[, list(estimate = estimate(first_time)), keyby = by]
    out[, process := proc]
    out
  })

  res <- data.table::rbindlist(res)
  data.table::setcolorder(res, c(by, "process", "estimate"))
  data.table::setnames(res, "estimate", type)
  res[]
}
