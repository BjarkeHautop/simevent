test_that("plot_event_data returns a ggplot object for sim_event_graph() output", {
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 20)

  p <- plot_event_data(data)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Event Data")
})

test_that("plot_event_data respects a custom title", {
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    relapse = sim_process("transient", eta = 0.2, nu = 1)
  )
  data <- sim_event_graph(graph, n = 15)

  p <- plot_event_data(data, title = "My Title")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "My Title")
})

test_that("plot_event_data works with many event types (color scales, shape doesn't)", {
  # 10 competing terminal processes -> more than ggplot2's default shape
  # scale can distinguish (max 6), so building the plot triggers ggplot2's
  # own shape-scale warning; color has no such limit.
  processes <- stats::setNames(
    lapply(seq_len(10), function(i) {
      sim_process("terminal", eta = 0.3, nu = 1.1)
    }),
    paste0("cause", seq_len(10))
  )
  graph <- do.call(sim_graph, processes)

  data <- sim_event_graph(graph, n = 30)
  p <- plot_event_data(data)
  expect_s3_class(p, "ggplot")
  expect_warning(
    ggplot2::ggplot_build(p),
    "shape palette can deal with a maximum of 6"
  )
})

test_that("plot_event_data lets the caller override the palette", {
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 10)

  p <- plot_event_data(data) +
    ggplot2::scale_color_manual(
      values = c(start = "grey", `0` = "blue", `1` = "red")
    )
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)
  expect_true(all(built$data[[2]]$colour %in% c("blue", "red")))
})
