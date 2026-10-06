test_that("sim_marker validates its inputs", {
  draw <- function(N) rnorm(N)
  expect_error(sim_marker(1, "visit", draw), "function")
  expect_error(
    sim_marker(function(n) rnorm(n), "visit", draw),
    "formal argument named 'N'"
  )
  expect_error(sim_marker(draw, 1, draw), "character")
  expect_error(sim_marker(draw, "visit", 1), "function")
  expect_s3_class(sim_marker(draw, "visit", draw), "sim_marker")
})

test_that("sim_model validates a marker's init, update and draw", {
  visit <- sim_process("transient", eta = 1, nu = 1)
  death <- sim_process("terminal", eta = 0.1, nu = 1)
  marker <- function(...) {
    args <- utils::modifyList(
      list(
        init = function(N) rnorm(N),
        update = "visit",
        draw = function(N) rnorm(N)
      ),
      list(...)
    )
    do.call(sim_marker, args)
  }

  expect_s3_class(
    sim_model(m = marker(), visit = visit, death = death),
    "sim_model"
  )
  expect_error(
    sim_model(
      m = marker(init = function(N, age) age),
      visit = visit,
      death = death
    ),
    "do not name an earlier"
  )
  expect_error(
    sim_model(m = marker(update = "death"), visit = visit, death = death),
    "\"transient\""
  )
  expect_error(
    sim_model(m = marker(update = "nope"), visit = visit, death = death),
    "\"transient\""
  )
  expect_error(
    sim_model(
      m = marker(draw = function(N, bogus) bogus),
      visit = visit,
      death = death
    ),
    "draw argument\\(s\\) 'bogus'"
  )
  expect_s3_class(
    sim_model(
      m = marker(draw = function(N, t, m, visit, age) m + t + visit + age),
      visit = visit,
      age = sim_covariate(function(N) rnorm(N)),
      death = death
    ),
    "sim_model"
  )
})

test_that("a marker is redrawn only at its update events, from current values", {
  model <- sim_model(
    bp = sim_marker(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(bp) bp + 1
    ),
    bp0 = sim_derived(function(bp) bp),
    visit = sim_process("transient", eta = 1, nu = 1),
    other = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 200, max_cens = 5, seed = 1)
  expect_gt(sum(data$event == "other"), 0)
  expect_equal(data$bp, data$bp0 + data$visit)
})

test_that("a marker's draw gets N, t and counts including the triggering event", {
  model <- sim_model(
    tm = sim_marker(
      init = function(N) rep(-1, N),
      update = c("visit", "other"),
      draw = function(N, t, visit) t + 100 * visit + 0 * N
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    other = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 200, max_cens = 5, seed = 1)
  updated <- data$event %in% c("visit", "other")
  expect_equal(data$tm[updated], data$time[updated] + 100 * data$visit[updated])
})

test_that("intervening on a marker fixes it for all time", {
  model <- sim_model(
    bp = sim_marker(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(bp) bp + 1
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 100, intervene = list(bp = 3), seed = 1)
  expect_true(all(data$bp == 3))
})

test_that("a marker's draw must return a numeric vector of length N", {
  model <- sim_model(
    bp = sim_marker(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) 1
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1)
  )
  expect_error(
    sim_events(model, n = 50, seed = 1),
    "length N"
  )
})

test_that("hazards use the marker's current value", {
  model <- sim_model(
    bp = sim_marker(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    bp0 = sim_derived(function(bp) bp),
    visit = sim_process("transient", eta = 2, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect("bp", "death", coef = 0.7))
  )
  data <- sim_events(model, n = 3000, max_cens = 5, seed = 1)

  # Value in force during each row's interval: the previous row's value.
  bp <- time <- id <- NULL
  data[, bp_now := data.table::shift(bp, fill = bp0[1]), by = id]
  data[, tstart := data.table::shift(time, fill = 0), by = id]
  fit <- survival::coxph(
    survival::Surv(tstart, time, event == "death") ~ bp_now,
    data = data
  )
  expect_equal(unname(stats::coef(fit)), 0.7, tolerance = 0.1)
})

test_that("summary() labels markers", {
  model <- sim_model(
    bp = sim_marker(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1)
  )
  expect_equal(summary(model)$covariates$kind, "marker")
})
