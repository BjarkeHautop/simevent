test_that("sim_mark validates its inputs", {
  draw <- function(N, lp) rnorm(N, lp)
  expect_error(sim_mark(1, "visit", draw), "function")
  expect_error(
    sim_mark(function(n) rnorm(n), "visit", draw),
    "formal argument named 'N'"
  )
  expect_error(sim_mark(draw, 1, draw), "character")
  expect_error(sim_mark(draw, "visit", 1), "function")
  expect_error(
    sim_mark(draw, "visit", function(N, bp) bp),
    "may only take 'N' and 'lp'; got 'bp'"
  )
  expect_s3_class(sim_mark(draw, "visit", draw), "sim_mark")
  expect_s3_class(sim_mark(draw, "visit", function(N) rnorm(N)), "sim_mark")
})

test_that("sim_model validates a mark's init, update and effects", {
  visit <- sim_process("transient", eta = 1, nu = 1)
  death <- sim_process("terminal", eta = 0.1, nu = 1)
  mark <- function(...) {
    args <- utils::modifyList(
      list(
        init = function(N) rnorm(N),
        update = "visit",
        draw = function(N, lp) rnorm(N, lp)
      ),
      list(...)
    )
    do.call(sim_mark, args)
  }

  expect_s3_class(
    sim_model(m = mark(), visit = visit, death = death),
    "sim_model"
  )
  expect_error(
    sim_model(
      m = mark(init = function(N, age) age),
      visit = visit,
      death = death
    ),
    "do not name an earlier"
  )
  expect_error(
    sim_model(m = mark(update = "death"), visit = visit, death = death),
    "\"transient\""
  )
  expect_error(
    sim_model(m = mark(update = "nope"), visit = visit, death = death),
    "\"transient\""
  )
  expect_s3_class(
    sim_model(
      m = mark(),
      visit = visit,
      age = sim_covariate(function(N) rnorm(N)),
      death = death,
      effects = list(
        sim_effect("m", "m", coef = 0.5),
        sim_effect("t + visit + age", "m", coef = 1)
      )
    ),
    "sim_model"
  )
  expect_error(
    sim_model(
      m = mark(),
      x = sim_covariate(function(N) rnorm(N)),
      visit = visit,
      death = death,
      effects = list(sim_effect("m", "x", coef = 1))
    ),
    "sim_process\\(\\) or sim_mark\\(\\)"
  )
  expect_error(
    sim_model(
      m = mark(),
      visit = visit,
      death = death,
      effects = list(sim_effect("death", "m", coef = 1))
    ),
    "censoring/terminal"
  )
})

test_that("a mark is redrawn only at its update events, from current values", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(lp) lp + 1
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    other = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect("bp", "bp", coef = 1))
  )
  data <- sim_events(model, n = 200, max_cens = 5, seed = 1)
  expect_gt(sum(data$event == "other"), 0)
  expect_equal(data$bp, data$bp_0 + data$visit)
})

test_that("a mark's lp sees t, counts and event times including the triggering event", {
  model <- sim_model(
    tm = sim_mark(
      init = function(N) rep(-1, N),
      update = c("visit", "other"),
      draw = function(N, lp) lp + 0 * N
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    other = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(
      sim_effect("t", "tm", coef = 1),
      sim_effect("visit", "tm", coef = 100),
      sim_effect("last_time(visit) == t", "tm", coef = 1000)
    )
  )
  data <- sim_events(model, n = 200, max_cens = 5, seed = 1)
  updated <- data$event %in% c("visit", "other")
  expect_equal(
    data$tm[updated],
    data$time[updated] +
      100 * data$visit[updated] +
      1000 * (data$event[updated] == "visit")
  )
})

test_that("a mark with no incoming effects gets lp = 0", {
  model <- sim_model(
    m = sim_mark(
      init = function(N) rep(1, N),
      update = "visit",
      draw = function(lp) lp
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 100, max_cens = 5, seed = 1)
  expect_true(all(data$m == ifelse(data$visit > 0, 0, 1)))
})

test_that("effects into a mark don't change any hazard", {
  base <- list(
    m = sim_mark(
      init = function(N) rep(0, N),
      update = "visit",
      draw = function(N) rep(0, N)
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  without <- do.call(sim_model, base)
  with <- do.call(
    sim_model,
    c(base, list(effects = list(sim_effect("t", "m", coef = 1))))
  )
  expect_equal(
    sim_events(with, n = 100, max_cens = 5, seed = 1),
    sim_events(without, n = 100, max_cens = 5, seed = 1)
  )
})

test_that("intervening on a mark fixes it for all time", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(lp) lp + 1
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect("bp", "bp", coef = 1))
  )
  data <- sim_events(model, n = 100, intervene = list(bp = 3), seed = 1)
  expect_true(all(data$bp == 3))
})

test_that("sim_events outputs each mark's baseline value after it", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    .hidden = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    age = sim_covariate(function(N) rnorm(N)),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  data <- sim_events(model, n = 100, max_cens = 5, seed = 1)
  expect_equal(
    names(data),
    c("id", "time", "event", "bp", "bp_0", "age", "visit")
  )
  bp_0 <- NULL
  expect_true(all(data[, data.table::uniqueN(bp_0), by = id]$V1 == 1))
  expect_equal(data$bp_0[data$visit == 0], data$bp[data$visit == 0])

  fixed <- sim_events(model, n = 10, intervene = list(bp = 3), seed = 1)
  expect_true(all(fixed$bp_0 == 3))
})

test_that("sim_model rejects nodes named like a mark's baseline column", {
  expect_error(
    sim_model(
      bp = sim_mark(function(N) rnorm(N), "visit", function(N) rnorm(N)),
      bp_0 = sim_covariate(function(N) rnorm(N)),
      visit = sim_process("transient", eta = 1, nu = 1),
      death = sim_process("terminal", eta = 0.2, nu = 1)
    ),
    "baseline-value column.*bp_0"
  )
})

test_that("a mark's draw must return a numeric vector of length N", {
  model <- sim_model(
    bp = sim_mark(
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

test_that("hazards use the mark's current value", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N) rnorm(N)
    ),
    visit = sim_process("transient", eta = 2, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect("bp", "death", coef = 0.7))
  )
  data <- sim_events(model, n = 3000, max_cens = 5, seed = 1)

  fit <- survival::coxph(
    survival::Surv(tstart, tstop, event == "death") ~ bp,
    data = interval_format_data(data, mark_cols = "bp")
  )
  expect_equal(unname(stats::coef(fit)), 0.7, tolerance = 0.1)
})

test_that("summary() labels marks and unrolls effects into them", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N, lp) rnorm(N, lp)
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(
      sim_effect("bp", "bp", coef = 0.8),
      sim_effect("(bp - 130)^2 + T_visit.1", "bp", coef = 0.1),
      sim_effect("visit", "bp", coef = 1),
      sim_effect("bp", "death", coef = 0.1)
    )
  )
  s <- summary(model)
  expect_equal(s$covariates$kind, "mark")
  expect_equal(
    s$effects$from,
    c("bp[k]", "(bp[k] - 130)^2 + T_visit.1", "visit", "bp")
  )
  expect_equal(s$effects$to, c("bp[k+1]", "bp[k+1]", "bp[k+1]", "death"))
  expect_output(print(s), "k-th update")
})
