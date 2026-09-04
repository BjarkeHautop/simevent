test_that("plotEventData returns a ggplot object for simEventData output", {
  set.seed(300)
  data_test <- simEventData(20)
  p <- plotEventData(data_test)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Event Data")
})

test_that("plotEventData respects a custom title", {
  set.seed(301)
  data_test <- simDisease(15)
  p <- plotEventData(data_test, title = "My Title")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "My Title")
})

test_that("plotEventData works with many event types (color/shape recycling)", {
  set.seed(302)
  # 10 event types -> exceeds the built-in palette of 9 colors/shapes,
  # exercising the "warning + recycle" branch.
  beta <- matrix(0, nrow = 12, ncol = 10)
  at_risk <- function(events) rep(1, 10)
  data_test <- simEventData(
    30,
    beta = beta,
    eta = rep(0.3, 10),
    nu = rep(1.1, 10),
    at_risk = at_risk,
    max_events = 20
  )
  expect_warning(
    p <- plotEventData(data_test),
    "More event types than available colors"
  )
  expect_s3_class(p, "ggplot")
})
