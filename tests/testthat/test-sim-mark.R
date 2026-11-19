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
        sim_effect(m ~ m(event_time(visit, -1)), coef = 0.5),
        sim_effect(m ~ t + visit(t) + age, coef = c(1, 1, 1))
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
      effects = list(sim_effect(x ~ m, coef = 1))
    ),
    "sim_process\\(\\) or sim_mark\\(\\)"
  )
  expect_error(
    sim_model(
      m = mark(),
      visit = visit,
      death = death,
      effects = list(sim_effect(m ~ death, coef = 1))
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
    effects = list(sim_effect(bp ~ bp(event_time(visit, -1)), coef = 1))
  )
  data <- simulate_events(model, n = 200, max_cens = 5, seed = 1)
  expect_gt(sum(data$event == "other"), 0)
  expect_equal(data$bp, data$bp_0 + data$visit)
})

test_that("a mark's lp sees t, and the triggering event only through calls at t", {
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
      sim_effect(tm ~ t, coef = 1),
      sim_effect(tm ~ visit(t), coef = 100),
      sim_effect(tm ~ event_time(visit, -1), coef = 1000)
    )
  )
  data <- simulate_events(model, n = 200, max_cens = 5, seed = 1)
  # event_time(visit, -1) is the latest visit before the triggering event.
  data[,
    prev_visit := data.table::shift(
      data.table::nafill(ifelse(event == "visit", time, NA_real_), "locf"),
      fill = 0
    ),
    by = id
  ]
  data[is.na(prev_visit), prev_visit := 0]
  updated <- data$event %in% c("visit", "other")
  expect_equal(
    data$tm[updated],
    data$time[updated] +
      100 * data$visit[updated] +
      1000 * data$prev_visit[updated]
  )
})

test_that("effects into a mark use values before the event unless called at t", {
  model <- sim_model(
    a = sim_mark(function(N) rep(0, N), "visit", function(N, lp) lp + 0 * N),
    b = sim_mark(function(N) rep(0, N), "visit", function(N, lp) lp + 0 * N),
    c = sim_mark(function(N) rep(0, N), "visit", function(N, lp) lp + 0 * N),
    lab = sim_mark(function(N) rep(5, N), "check", function(N) rnorm(N)),
    visit = sim_process("transient", eta = 1, nu = 1),
    check = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(
      # a is defined first, but uses b at this visit, so b is drawn first.
      sim_effect(a ~ b(t), coef = 1),
      sim_effect(b ~ visit(t), coef = 1),
      sim_effect(c ~ b(event_time(visit, -1)), coef = 1),
      # lab isn't redrawn at visits, so it can be used as is.
      sim_effect(c ~ lab, coef = 1000)
    )
  )
  data <- simulate_events(model, n = 200, max_cens = 5, seed = 1)
  visits <- data$event == "visit"
  expect_equal(data$b[visits], data$visit[visits])
  expect_equal(data$a[visits], data$b[visits])
  lab_before <- data[, data.table::shift(lab, fill = lab_0[1]), by = id]$V1
  expect_equal(
    data$c[visits],
    pmax(data$visit[visits] - 1, 0) + 1000 * lab_before[visits]
  )
})

test_that("sim_model rejects ambiguous uses in effects into a mark", {
  base <- list(
    a = sim_mark(function(N) rnorm(N), "visit", function(N, lp) lp),
    b = sim_mark(function(N) rnorm(N), "visit", function(N, lp) lp),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1)
  )
  with_effects <- function(...) {
    do.call(sim_model, c(base, list(effects = list(...))))
  }
  expect_error(
    with_effects(sim_effect(a ~ a, coef = 1)),
    "a\\(event_time\\(visit, -1\\)\\) for its value at the previous visit\\."
  )
  expect_error(
    with_effects(sim_effect(a ~ b, coef = 1)),
    "or b\\(t\\) for its value at this one"
  )
  expect_error(
    with_effects(sim_effect(a ~ visit, coef = 1)),
    "visit\\(t\\) - 1"
  )
  expect_error(
    with_effects(sim_effect(a ~ a(t), coef = 1)),
    "the value being drawn"
  )
  expect_error(
    with_effects(
      sim_effect(a ~ b(t), coef = 1),
      sim_effect(b ~ a(t), coef = 1)
    ),
    "cycle"
  )
  # event_time()'s process argument isn't a use of its count.
  expect_s3_class(
    with_effects(sim_effect(a ~ event_time(visit, -1), coef = 1)),
    "sim_model"
  )
})

test_that("using a mark at an event before it's redrawn there is an error", {
  model <- sim_model(
    a = sim_mark(function(N) rnorm(N), "visit", function(N, lp) lp),
    b = sim_mark(function(N) rnorm(N), "visit", function(N, lp) lp),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect(a ~ b(t + 0), coef = 1))
  )
  expect_error(
    simulate_events(model, n = 20, max_cens = 5, seed = 1),
    "hasn't been drawn yet"
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
  data <- simulate_events(model, n = 100, max_cens = 5, seed = 1)
  expect_equal(data$m, ifelse(data$visit > 0, 0, 1))
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
    c(base, list(effects = list(sim_effect(m ~ t, coef = 1))))
  )
  expect_equal(
    simulate_events(with, n = 100, max_cens = 5, seed = 1),
    simulate_events(without, n = 100, max_cens = 5, seed = 1)
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
    effects = list(sim_effect(bp ~ bp(event_time(visit, -1)), coef = 1))
  )
  data <- simulate_events(model, n = 100, intervene = list(bp = 3), seed = 1)
  expect_in(data$bp, 3)
})

test_that("simulate_events outputs each mark's baseline value after it", {
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
  data <- simulate_events(model, n = 100, max_cens = 5, seed = 1)
  expect_equal(
    names(data),
    c("id", "time", "event", "bp", "bp_0", "age", "visit")
  )
  bp_0 <- NULL
  expect_in(data[, data.table::uniqueN(bp_0), by = id]$V1, 1)
  expect_equal(data$bp_0[data$visit == 0], data$bp[data$visit == 0])

  fixed <- simulate_events(model, n = 10, intervene = list(bp = 3), seed = 1)
  expect_in(fixed$bp_0, 3)
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
    simulate_events(model, n = 50, seed = 1),
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
    effects = list(sim_effect(death ~ bp, coef = 0.7))
  )
  data <- simulate_events(model, n = 3000, max_cens = 5, seed = 1)

  fit <- survival::coxph(
    survival::Surv(tstart, tstop, event == "death") ~ bp,
    data = format_interval_data(data, mark_cols = "bp")
  )
  expect_equal(unname(stats::coef(fit)), 0.7, tolerance = 0.1)
})

test_that("effects into a mark are recovered by regressing its new values", {
  model <- sim_model(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    visit = sim_process("transient", eta = 1, nu = 1),
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N, lp) rnorm(N, mean = lp)
    ),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(
      sim_effect(bp ~ L0, 0.5),
      sim_effect(bp ~ bp(event_time(visit, -1)), 0.6),
      sim_effect(bp ~ t, 0.1)
    )
  )
  data <- simulate_events(model, n = 1000, max_cens = 5, seed = 1)

  # Each visit's new bp against the value before it and the visit time.
  data_int <- format_interval_data(data, mark_cols = "bp")
  visits <- data_int[data_int$event == "visit", ]
  visits$bp_new <- data$bp[data$event == "visit"]
  fit <- stats::lm(bp_new ~ 0 + L0 + bp + time, data = visits)
  expect_ci_covers(fit, c(0.5, 0.6, 0.1))
})

test_that("summary() labels marks and lists effects into them", {
  model <- sim_model(
    bp = sim_mark(
      init = function(N) rnorm(N),
      update = "visit",
      draw = function(N, lp) rnorm(N, lp)
    ),
    visit = sim_process("transient", eta = 1, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(
      sim_effect(bp ~ bp(event_time(visit, -1)), coef = 0.8),
      sim_effect(death ~ bp, coef = 0.1)
    )
  )
  s <- summary(model)
  expect_equal(s$covariates$kind, "mark")
  expect_equal(s$effects$from, c("bp(event_time(visit, -1))", "bp"))
  expect_equal(s$effects$to, c("bp", "death"))
})
