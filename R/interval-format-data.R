#' Convert Simulated Event Data to Start-Stop Format
#'
#' Converts [sim_events()] output to start-stop format for
#' `coxph(Surv(tstart, tstop, ...))`.
#'
#' @param data Output of [sim_events()].
#' @param proc_cols Character vector. `"transient"`-process columns to use
#'   as time-varying covariates: each row then holds the count *before* its
#'   event.
#' @param mark_cols Character vector. [sim_mark()] columns to use as
#'   time-varying covariates: each row then holds the value *before* its
#'   event, i.e. the one in force during its interval, taken from the
#'   `<name>_0` baseline column for the first row.
#' @param time_var Logical. Split intervals at `t_prime`? Default `FALSE`.
#' @param t_prime Numeric. Split time. Adds a `t_group` column (1 before,
#'   2 after), so an effect can differ between the periods (see Examples).
#'   The first half of a split interval has `event = "none"`.
#'
#' @return `data` with added columns `tstart`, `tstop` and `k` (event
#'   number).
#' @seealso [sim_events()]
#' @examples
#' model <- sim_model(
#'   L0 = sim_covariate(function(N) runif(N)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   relapse = sim_process("transient", eta = 0.2, nu = 1),
#'   effects = list(sim_effect("relapse", "death", 0.5))
#' )
#' data <- sim_events(model, n = 500)
#' data_int <- interval_format_data(data, proc_cols = "relapse")
#' head(data_int)
#'
#' # relapse is now the cumulative count *before* each row's event, so it can
#' # be used as a time-varying covariate:
#' survival::coxph(
#'   survival::Surv(tstart, tstop, event == "death") ~ L0 + relapse,
#'   data = data_int
#' )
#'
#' # Splitting at t_prime tests whether an effect changes over time. Here L0
#' # raises the death hazard before time 2 only:
#' model_tv <- sim_model(
#'   L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
#'   death = sim_process("terminal", eta = 0.2, nu = 1),
#'   effects = list(sim_effect("L0 * (t < 2)", "death", coef = 1))
#' )
#' data_tv <- sim_events(model_tv, n = 2000)
#' data_split <- interval_format_data(data_tv, time_var = TRUE, t_prime = 2)
#'
#' # One L0 coefficient per period: about 1 before t_prime, about 0 after.
#' survival::coxph(
#'   survival::Surv(tstart, tstop, event == "death") ~ L0:strata(t_group),
#'   data = data_split
#' )
#' @export
interval_format_data <- function(
  data,
  proc_cols = character(0),
  mark_cols = character(0),
  time_var = FALSE,
  t_prime = NULL
) {
  id <- k <- tstart <- tstop <- time <- t_group <- event <- NULL
  checkmate::assert_character(proc_cols, any.missing = FALSE)
  checkmate::assert_character(mark_cols, any.missing = FALSE)
  checkmate::assert_names(
    names(data),
    must.include = c(mark_cols, sprintf("%s_0", mark_cols))
  )
  checkmate::assert_flag(time_var)
  checkmate::assert_number(t_prime, finite = TRUE, null.ok = !time_var)
  data <- data.table::copy(data.table::as.data.table(data))

  if (length(proc_cols) > 0) {
    data[,
      (proc_cols) := lapply(.SD, data.table::shift, fill = 0),
      by = id,
      .SDcols = proc_cols
    ]
  }
  if (length(mark_cols) > 0) {
    data[,
      (mark_cols) := lapply(.SD, data.table::shift),
      by = id,
      .SDcols = mark_cols
    ]
    first <- which(!duplicated(data$id))
    for (nm in mark_cols) {
      data.table::set(data, first, nm, data[[paste0(nm, "_0")]][first])
    }
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
    if (is.factor(res$event)) {
      levels(res$event) <- union(levels(res$event), "none")
    }
    rows_to_split <- res[tstart <= t_prime & tstop > t_prime]

    data1 <- data.table::copy(rows_to_split)[, `:=`(
      tstop = t_prime,
      time = t_prime,
      event = "none"
    )]
    data2 <- data.table::copy(rows_to_split)[, `:=`(tstart = t_prime)]

    data_new <- res[!(tstart <= t_prime & tstop > t_prime)]
    res <- rbind(data_new, data1, data2)

    res[, t_group := (1 + (time > t_prime))]
  }

  data.table::setorder(res, id, tstart)
  res[]
}
