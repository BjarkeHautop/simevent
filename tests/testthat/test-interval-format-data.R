test_that("interval_format_data builds tstart/tstop intervals from sim_events() output", {
  set.seed(300)
  model <- sim_model(
    L0 = sim_covariate(function(N) runif(N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_events(model, n = 20)

  data_int <- interval_format_data(data)

  expect_true(all(c("tstart", "tstop", "k") %in% names(data_int)))
  expect_true(all(data_int$tstart < data_int$tstop))
  first_rows <- data_int[data_int$k == 1, ]
  expect_true(all(first_rows$tstart == 0))
})

test_that("interval_format_data lags a transient process's count by one row per id", {
  set.seed(301)
  model <- sim_model(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1),
    relapse = sim_process("transient", eta = 0.5, nu = 1)
  )
  data <- sim_events(model, n = 50)
  # Restrict to individuals with at least one relapse, so there's something
  # to lag.
  multi_event_ids <- data[data$relapse > 0, ]$id

  data_int <- interval_format_data(data, proc_cols = "relapse")

  for (an_id in unique(multi_event_ids)) {
    rows <- data_int[data_int$id == an_id, ][order(k)]
    original_rows <- data[data$id == an_id, ][order(time)]
    # Row k's relapse count is the *pre-event* count, i.e. row (k-1)'s
    # already-fired count in the original (un-lagged) data.
    expect_equal(
      rows$relapse,
      c(0, original_rows$relapse[-nrow(original_rows)])
    )
  }
})

test_that("interval_format_data splits intervals at t_prime when time_var = TRUE", {
  set.seed(302)
  model <- sim_model(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1)
  )
  data <- sim_events(model, n = 100)
  t_prime <- stats::median(data$time)

  data_int <- interval_format_data(data, time_var = TRUE, t_prime = t_prime)

  # No remaining interval should straddle t_prime once splitting is applied.
  expect_true(!any(data_int$tstart < t_prime & data_int$tstop > t_prime))
  expect_true(any(data_int$tstop == t_prime))
})

test_that("interval_format_data requires t_prime when time_var = TRUE", {
  model <- sim_model(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1)
  )
  data <- sim_events(model, n = 10, seed = 1)

  expect_error(interval_format_data(data, time_var = TRUE), "t_prime")
  expect_no_error(interval_format_data(data, t_prime = NULL))
})

test_that("interval_format_data labels the pre-t_prime half of a split as \"none\"", {
  model <- sim_model(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1)
  )
  data <- sim_events(model, n = 100, seed = 2)
  t_prime <- stats::median(data$time)

  data_int <- interval_format_data(data, time_var = TRUE, t_prime = t_prime)

  split_rows <- data_int[data_int$event == "none", ]
  expect_gt(nrow(split_rows), 0)
  expect_true(all(split_rows$tstop == t_prime))
  expect_false(anyNA(data_int$event))
})

test_that("interval_format_data lags a mark, from its baseline value", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 50, max_cens = 5, seed = 1)
  data_int <- interval_format_data(data, mark_cols = "bp")

  for (an_id in unique(data$id)) {
    rows <- data_int[data_int$id == an_id, ]
    original_rows <- data[data$id == an_id, ]
    expect_equal(
      rows$bp,
      c(original_rows$bp_0[1], original_rows$bp[-nrow(original_rows)])
    )
  }
  expect_error(
    interval_format_data(data[, !"bp_0"], mark_cols = "bp"),
    "bp_0"
  )
})
