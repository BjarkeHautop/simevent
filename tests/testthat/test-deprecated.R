test_that("deprecated functions warn and still return their results", {
  withr::local_options(lifecycle_verbosity = "warning")

  expect_warning(
    data <- simEventData(5),
    class = "lifecycle_warning_deprecated"
  )
  expect_s3_class(data, "data.table")

  expect_warning(
    simSurvData(5),
    "sim_event_graph",
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    p <- plotEventData(data),
    "plot_event_data",
    class = "lifecycle_warning_deprecated"
  )
  expect_s3_class(p, "ggplot")
  expect_warning(
    IntFormatData(data),
    "interval_format_data",
    class = "lifecycle_warning_deprecated"
  )
})

test_that("internal callers of deprecated functions do not warn", {
  withr::local_options(lifecycle_verbosity = "warning")

  expect_no_warning(
    .alphaSim(
      N = 50,
      eta = rep(0.1, 3),
      nu = rep(1.1, 3),
      alpha = 0.5,
      setting = "Disease"
    )
  )
})
