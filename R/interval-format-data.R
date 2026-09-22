#' Transform Graph-Based Event Data into Interval Format for Classical Inference
#'
#' Converts [sim_event_graph()] output into an interval (start-stop) format,
#' suitable for classical survival analysis functions like `coxph()`. Adds
#' interval start and stop times (`tstart`, `tstop`) and a counting variable
#' `k` indexing events. Optionally, the function can split intervals at a
#' specified time point to accommodate estimation of time-varying effects.
#'
#' @param data A `data.table` as returned by [sim_event_graph()]: columns
#'   `id`, `time`, `delta`, baseline covariates, and one column per
#'   `"transient"` process.
#' @param proc_cols Character vector. Names of `data`'s `"transient"`-process
#'   columns (e.g. `names(graph$processes)` restricted to the transient
#'   ones), which get lagged by one row per `id` so each interval reports
#'   the process's cumulative count *before* that row's event. Default
#'   `character(0)` (no transient-process columns to lag).
#' @param time_var Logical. If `TRUE`, the intervals are split at `t_prime`
#'   to allow time-varying covariate effects. Default `FALSE`.
#' @param t_prime Numeric scalar. Time point at which to split intervals if
#'   `time_var = TRUE`.
#'
#' @return A `data.table` with columns `tstart`, `tstop`, `k`, and the other
#'   original columns, formatted for survival analysis.
#' @seealso [sim_event_graph()]
#' @examples
#' graph <- sim_graph(
#'   L0 = sim_covariate(function(N) runif(N)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   relapse = sim_process("transient", eta = 0.2, nu = 1),
#'   effects = list(sim_effect("relapse", "death", 0.5))
#' )
#' data <- sim_event_graph(graph, n = 500)
#' data_int <- interval_format_data(data, proc_cols = "relapse")
#' head(data_int)
#'
#' # relapse is now the cumulative count *before* each row's event, so it can
#' # be used as a time-varying covariate:
#' survival::coxph(
#'   survival::Surv(tstart, tstop, delta == 1) ~ L0 + relapse,
#'   data = data_int
#' )
#' @export
interval_format_data <- function(
  data,
  proc_cols = character(0),
  time_var = FALSE,
  t_prime = NULL
) {
  id <- k <- tstart <- tstop <- time <- t_group <- NULL
  data <- data.table::copy(data.table::as.data.table(data))

  if (length(proc_cols) > 0) {
    data[,
      (proc_cols) := lapply(.SD, data.table::shift, fill = 0),
      by = id,
      .SDcols = proc_cols
    ]
  }

  data[, k := stats::ave(id, id, FUN = seq_along)]
  max_k <- max(data$k)

  data_k <- list()
  data_k[[1]] <- data[data$k == 1, ]

  data_k[[1]][, tstart := 0]
  data_k[[1]][, tstop := time]

  for (i in seq_len(max_k)[-1]) {
    data_k[[i]] <- data[data$k == i, ]

    data_k[[i]][,
      tstart := data_k[[i - 1]][data_k[[i - 1]]$id %in% data_k[[i]]$id, ]$tstop
    ]
    data_k[[i]][, tstop := time]
  }

  res <- do.call(rbind, data_k)

  if (time_var) {
    rows_to_split <- res[tstart <= t_prime & tstop > t_prime]

    data1 <- data.table::copy(rows_to_split)[, `:=`(
      tstop = t_prime,
      time = t_prime,
      delta = -1
    )]
    data2 <- data.table::copy(rows_to_split)[, `:=`(tstart = t_prime)]

    data_new <- res[!(tstart <= t_prime & tstop > t_prime)]
    res <- rbind(data_new, data1, data2)

    res[, t_group := (1 + (time > t_prime))]
  }

  data.table::setorder(res, id, tstart)
  res[]
}
