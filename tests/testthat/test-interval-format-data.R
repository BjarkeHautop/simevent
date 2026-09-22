test_that("interval_format_data builds tstart/tstop intervals from sim_event_graph() output", {
  set.seed(300)
  graph <- sim_graph(
    L0 = sim_covariate(function(N) runif(N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 20)

  data_int <- interval_format_data(data)

  expect_true(all(c("tstart", "tstop", "k") %in% names(data_int)))
  expect_true(all(data_int$tstart < data_int$tstop))
  first_rows <- data_int[data_int$k == 1, ]
  expect_true(all(first_rows$tstart == 0))
})

test_that("interval_format_data lags a transient process's count by one row per id", {
  set.seed(301)
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1),
    relapse = sim_process("transient", eta = 0.5, nu = 1)
  )
  data <- sim_event_graph(graph, n = 50)
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
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1)
  )
  data <- sim_event_graph(graph, n = 100)
  t_prime <- stats::median(data$time)

  data_int <- interval_format_data(data, time_var = TRUE, t_prime = t_prime)

  # No remaining interval should straddle t_prime once splitting is applied.
  expect_true(!any(data_int$tstart < t_prime & data_int$tstop > t_prime))
  expect_true(any(data_int$tstop == t_prime))
})
