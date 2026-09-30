test_that("sim_covariate/sim_process/sim_effect validate their inputs", {
  expect_error(sim_covariate(1), "function")
  expect_error(sim_covariate(function(n) rnorm(n)), "formal argument named 'N'")
  expect_s3_class(sim_covariate(function(N) rnorm(N)), "sim_covariate")
  expect_s3_class(
    sim_covariate(function(N, age) rnorm(N) + age),
    "sim_covariate"
  )

  expect_error(sim_process("bogus", eta = 0.1, nu = 1.1), "arg")
  expect_error(sim_process("terminal", eta = -1, nu = 1.1), ">= 0")
  expect_s3_class(sim_process("terminal", eta = 0.1, nu = 1.1), "sim_process")

  expect_error(sim_effect(1, "b", 1), "string")
  expect_s3_class(sim_effect("a", "b", 1), "sim_effect")

  expect_error(sim_derived(function(N, region) region), "should not take 'N'")
  expect_error(sim_derived(function() 1), "at least one other covariate")
  expect_s3_class(
    sim_derived(function(region) as.numeric(region == 2)),
    "sim_derived"
  )
})

test_that("sim_graph validates node types, effect endpoints, and requires a process", {
  cov <- sim_covariate(function(N) rnorm(N))
  proc <- sim_process("terminal", eta = 0.1, nu = 1.1)

  expect_error(sim_graph(a = 1, d = proc), "sim_covariate\\(\\),")
  expect_error(sim_graph(a = cov), "at least one sim_process")
  expect_error(
    sim_graph(a = cov, d = proc, effects = list(sim_effect("a", "nope", 1))),
    "not one"
  )
  expect_error(
    sim_graph(a = cov, d = proc, effects = list(sim_effect("d", "a", 1))),
    "not one"
  )
  expect_error(sim_graph(a = cov, a = proc), "unique")

  expect_error(
    sim_graph(
      a = cov,
      d = proc,
      effects = list(sim_effect("bogus + 1", "d", 1))
    ),
    "not found in graph: bogus"
  )
  expect_error(
    sim_graph(a = cov, d = proc, effects = list(sim_effect("a +* 1", "d", 1))),
    "neither a node name nor a parseable"
  )
  g <- sim_graph(
    a = cov,
    d = proc,
    effects = list(sim_effect("a^2", "d", 1), sim_effect("t >= 0", "d", 0.1))
  )
  expect_s3_class(g, "sim_graph")

  graph <- sim_graph(a = cov, d = proc, effects = list(sim_effect("a", "d", 1)))
  expect_s3_class(graph, "sim_graph")
  expect_named(graph$covariates, "a")
  expect_named(graph$processes, "d")
  expect_output(print(graph), "sim_graph")
})

test_that("sim_graph validates sim_derived() dependency ordering", {
  region <- sim_covariate(function(N) sample(1:3, N, replace = TRUE))
  region2 <- sim_derived(function(region) as.numeric(region == 2))
  proc <- sim_process("terminal", eta = 0.1, nu = 1.1)

  expect_error(
    sim_graph(region2 = region2, region = region, d = proc),
    "must be an earlier"
  )
  expect_error(
    sim_graph(region2 = region2, d = proc),
    "must be an earlier"
  )

  graph <- sim_graph(
    region = region,
    region2 = region2,
    d = proc,
    effects = list(sim_effect("region2", "d", 1))
  )
  expect_s3_class(graph, "sim_graph")
  expect_named(graph$covariates, c("region", "region2"))
})

test_that("sim_event_graph recovers categorical-level effects via sim_derived", {
  set.seed(1405)

  graph <- sim_graph(
    region = sim_covariate(function(N) {
      sample(1:3, N, replace = TRUE, prob = c(0.5, 0.3, 0.2))
    }),
    region2 = sim_derived(function(region) as.numeric(region == 2)),
    region3 = sim_derived(function(region) as.numeric(region == 3)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(
      sim_effect("region2", "death", coef = 1.2),
      sim_effect("region3", "death", coef = -0.8)
    )
  )
  data <- sim_event_graph(graph, n = 8000)

  expect_setequal(
    names(data),
    c("id", "time", "event", "region", "region2", "region3")
  )
  expect_true(all(data$region2 %in% c(0, 1)))

  fit <- coxph(Surv(time, event == "death") ~ factor(region), data = data)
  ci <- confint(fit)
  expect_true(ci["factor(region)2", 1] <= 1.2 & 1.2 <= ci["factor(region)2", 2])
  expect_true(
    ci["factor(region)3", 1] <= -0.8 & -0.8 <= ci["factor(region)3", 2]
  )
})

test_that("sim_event_graph's intervene fixes a sim_derived() covariate too", {
  graph <- sim_graph(
    region = sim_covariate(function(N) sample(1:3, N, replace = TRUE)),
    region2 = sim_derived(function(region) as.numeric(region == 2)),
    d = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect("region2", "d", 1))
  )
  data <- sim_event_graph(graph, n = 50, intervene = list(region2 = 1))

  expect_true(all(data$region2 == 1))
})

test_that("sim_event_graph does not force L0/A0 into the output", {
  set.seed(1405)
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 50)

  expect_setequal(names(data), c("id", "time", "event"))
})

test_that("sim_event_graph recovers effect coefficients", {
  set.seed(1405)

  graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.4)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(
      sim_effect("L0", "death", 1.5),
      sim_effect("L0", "censoring", -0.5)
    )
  )
  data <- sim_event_graph(graph, n = 4000)

  expect_setequal(names(data), c("id", "time", "event", "L0"))

  fit_death <- coxph(Surv(time, event == "death") ~ L0, data = data)
  expect_true(confint(fit_death)[1, 1] <= 1.5 & 1.5 <= confint(fit_death)[1, 2])

  fit_cens <- coxph(Surv(time, event == "censoring") ~ L0, data = data)
  expect_true(confint(fit_cens)[1, 1] <= -0.5 & -0.5 <= confint(fit_cens)[1, 2])
})

test_that("sim_event_graph: a threshold sim_effect() fires specifically on the k-th jump", {
  set.seed(1)

  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.01, nu = 1),
    relapse = sim_process("transient", eta = 0.3, nu = 1, limit = 5),
    death = sim_process("terminal", eta = 0.01, nu = 1),
    effects = list(sim_effect("relapse == 3", "death", coef = 8))
  )
  data <- sim_event_graph(graph, n = 2000, max_events = 40)

  deaths <- data[data$event == "death", ]
  expect_gt(nrow(deaths), 0)
  # A large jump in the death hazard right at relapse == 3 should mean most
  # deaths happen exactly there, not before or after.
  expect_gt(mean(deaths$relapse == 3), 0.8)
})

test_that("sim_event_graph reports named transient-process event counts", {
  set.seed(1405)

  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    relapse = sim_process("transient", eta = 0.2, nu = 1),
    effects = list(sim_effect("relapse", "death", 0.8))
  )
  data <- sim_event_graph(graph, n = 500)

  expect_setequal(names(data), c("id", "time", "event", "relapse"))
  expect_true(all(data$relapse >= 0))
  expect_true(any(data$relapse > 0))
})

test_that("sim_event_graph intervene fixes covariates and scales process intensities", {
  set.seed(1405)

  graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.4)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )

  data_fixed <- sim_event_graph(graph, n = 100, intervene = list(L0 = 1))
  expect_true(all(data_fixed$L0 == 1))

  data_base <- sim_event_graph(graph, n = 5000)
  data_high <- sim_event_graph(graph, n = 5000, intervene = list(death = 10))
  expect_true(
    mean(data_high$event == "death") > mean(data_base$event == "death")
  )

  expect_error(
    sim_event_graph(graph, n = 10, intervene = list(bogus = 1)),
    "unknown name"
  )
})

test_that("sim_event_graph's transient process is unlimited by default", {
  set.seed(1405)

  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1),
    illness = sim_process("transient", eta = 0.3, nu = 1)
  )
  data <- sim_event_graph(graph, n = 500)

  expect_true(any(data$illness > 1))
})

test_that("sim_event_graph's transient process respects limit = 1", {
  set.seed(1405)

  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1),
    illness = sim_process("transient", eta = 1, nu = 1, limit = 1)
  )
  data <- sim_event_graph(graph, n = 500)

  expect_true(all(data$illness <= 1))
})

test_that("sim_event_graph's transient process respects a custom limit", {
  set.seed(1405)

  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", eta = 0.05, nu = 1),
    illness = sim_process("transient", eta = 1, nu = 1, limit = 2)
  )
  data <- sim_event_graph(graph, n = 500)

  expect_true(all(data$illness <= 2))
  expect_true(any(data$illness == 2))
})

test_that("sim_graph_from_fits recovers the fitted event-type distribution", {
  set.seed(1405)
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  observed_data <- .simCRdata(N = 2000, beta = beta)

  fits <- list(
    censoring = coxph(Surv(Time, Delta == 0) ~ L0 + A0, data = observed_data),
    cause1 = coxph(Surv(Time, Delta == 1) ~ L0 + A0, data = observed_data),
    cause2 = coxph(Surv(Time, Delta == 2) ~ L0 + A0, data = observed_data)
  )
  types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")

  graph <- sim_graph_from_fits(fits, observed_data, types)
  expect_s3_class(graph, "sim_graph")

  new_data <- sim_event_graph(graph, n = 5000)
  expect_setequal(names(new_data), c("id", "time", "event", "L0", "A0"))

  observed_props <- prop.table(table(observed_data$Delta))
  simulated_props <- prop.table(table(new_data$event))
  expect_equal(
    as.numeric(observed_props),
    as.numeric(simulated_props[c("censoring", "cause1", "cause2")]),
    tolerance = 0.05
  )
})

test_that("sim_graph_from_fits builds sim_derived() dummies for a factor covariate", {
  set.seed(1405)
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  observed_data <- .simCRdata(N = 3000, beta = beta)
  observed_data$region <- factor(sample(
    c("a", "b", "c"),
    nrow(observed_data),
    replace = TRUE,
    prob = c(0.5, 0.3, 0.2)
  ))

  fits <- list(
    censoring = coxph(
      Surv(Time, Delta == 0) ~ L0 + region,
      data = observed_data
    ),
    cause1 = coxph(Surv(Time, Delta == 1) ~ L0 + region, data = observed_data),
    cause2 = coxph(Surv(Time, Delta == 2) ~ L0, data = observed_data)
  )
  types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")

  graph <- sim_graph_from_fits(fits, observed_data, types)
  expect_named(
    graph$covariates,
    c(".row", "L0", "region", "regionb", "regionc")
  )

  new_data <- sim_event_graph(graph, n = 3000)
  expect_setequal(
    names(new_data),
    c("id", "time", "event", "L0", "region", "regionb", "regionc")
  )
  expect_true(all(new_data$region %in% 1:3))
  expect_equal(new_data$regionb, as.numeric(new_data$region == 2))
  expect_equal(new_data$regionc, as.numeric(new_data$region == 3))
})

test_that("sim_graph_from_fits validates types/fits/limits", {
  fit <- coxph(Surv(Time, Delta == 0) ~ L0, data = .simSurvData(100))

  expect_error(
    sim_graph_from_fits(list(a = fit), .simSurvData(100), c(b = "censoring")),
    "permutation"
  )
  expect_error(
    sim_graph_from_fits(list(a = fit), .simSurvData(100), c(a = "bogus")),
    "subset"
  )
  expect_error(
    sim_graph_from_fits(
      list(a = "not a fit"),
      .simSurvData(100),
      c(a = "censoring")
    ),
    "coxph"
  )
})

test_that("sim_graph_from_fits wires a cross-process effect, not a bogus covariate", {
  set.seed(1405)

  observed_graph <- sim_graph(
    L0 = sim_covariate(function(N) runif(N)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    relapse = sim_process("transient", eta = 0.3, nu = 1),
    effects = list(
      sim_effect("L0", "death", 0.5),
      sim_effect("relapse", "death", 0.9)
    )
  )
  observed_data <- sim_event_graph(observed_graph, n = 500)

  fits <- list(
    censoring = coxph(
      Surv(time, event == "censoring") ~ L0,
      data = observed_data
    ),
    death = coxph(
      Surv(time, event == "death") ~ L0 + relapse,
      data = observed_data
    ),
    relapse = coxph(Surv(time, event == "relapse") ~ 1, data = observed_data)
  )
  types <- c(censoring = "censoring", death = "terminal", relapse = "transient")

  graph <- sim_graph_from_fits(fits, observed_data, types)

  # relapse must be a process node, not a baseline covariate rebuilt from
  # its (meaningless, since it's a running count, not a fixed baseline
  # value) observed values.
  expect_named(graph$covariates, c(".row", "L0"))
  expect_named(graph$processes, c("censoring", "death", "relapse"))

  effect_pairs <- vapply(
    graph$effects,
    function(e) paste(e$from, e$to, sep = "->"),
    character(1)
  )
  expect_true("relapse->death" %in% effect_pairs)

  new_data <- sim_event_graph(graph, n = 100)
  expect_setequal(names(new_data), c("id", "time", "event", "L0", "relapse"))
})

test_that("sim_graph_from_fits resamples observed covariate rows jointly", {
  set.seed(1405)
  observed_graph <- sim_graph(
    L0 = sim_covariate(function(N) runif(N)),
    A0 = sim_covariate(function(N, L0) rbinom(N, 1, plogis(-3 + 6 * L0))),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect("L0", "death", 1))
  )
  observed_data <- sim_event_graph(observed_graph, n = 1000)
  fits <- list(
    censoring = coxph(
      Surv(time, event == "censoring") ~ L0 + A0,
      observed_data
    ),
    death = coxph(Surv(time, event == "death") ~ L0 + A0, observed_data)
  )
  types <- c(censoring = "censoring", death = "terminal")

  graph <- sim_graph_from_fits(fits, observed_data, types)
  new_data <- sim_event_graph(graph, n = 1000)

  expect_true(all(new_data$L0 %in% observed_data$L0))
  expect_equal(
    cor(new_data$L0, new_data$A0),
    cor(observed_data$L0, observed_data$A0),
    tolerance = 0.1
  )
  expect_output(print(graph), "2 covariate\\(s\\): L0, A0")
  expect_equal(summary(graph)$covariates$name, c("L0", "A0"))
})

test_that("sim_graph_from_fits uses one row per id", {
  set.seed(1405)
  observed_graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    relapse = sim_process("transient", eta = 0.3, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect("L0", "relapse", 1.5))
  )
  observed_data <- interval_format_data(
    sim_event_graph(observed_graph, n = 2000, max_events = 200),
    proc_cols = "relapse"
  )
  fits <- list(
    censoring = coxph(
      Surv(tstart, tstop, event == "censoring") ~ L0,
      observed_data
    ),
    relapse = coxph(
      Surv(tstart, tstop, event == "relapse") ~ L0,
      observed_data
    ),
    death = coxph(
      Surv(tstart, tstop, event == "death") ~ L0 + relapse,
      observed_data
    )
  )
  types <- c(censoring = "censoring", relapse = "transient", death = "terminal")

  graph <- sim_graph_from_fits(fits, observed_data, types)
  new_data <- sim_event_graph(graph, n = 2000, max_events = 200)

  expect_equal(
    mean(new_data$L0[!duplicated(new_data$id)]),
    0.5,
    tolerance = 0.1
  )
})

test_that("sim_graph_from_fits handles transformed and interaction terms", {
  set.seed(1405)
  observed_graph <- sim_graph(
    L0 = sim_covariate(function(N) runif(N)),
    A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1)
  )
  observed_data <- sim_event_graph(observed_graph, n = 500)
  fits <- list(
    censoring = coxph(Surv(time, event == "censoring") ~ L0, observed_data),
    death = coxph(
      Surv(time, event == "death") ~ L0 * A0 + I(L0^2),
      observed_data
    )
  )
  types <- c(censoring = "censoring", death = "terminal")

  expect_no_warning(graph <- sim_graph_from_fits(fits, observed_data, types))
  froms <- vapply(graph$effects, `[[`, character(1), "from")
  expect_setequal(froms, c("L0", "A0", "I(L0^2)", "L0 * A0"))
  expect_s3_class(sim_event_graph(graph, n = 50), "data.table")
})

test_that("sim_graph_from_fits errors on a fit with too few events", {
  data <- .simSurvData(100)
  types <- c(censoring = "censoring", death = "terminal")
  fits <- list(
    censoring = coxph(Surv(Time, Delta == 99) ~ L0, data = data),
    death = coxph(Surv(Time, Delta == 1) ~ L0, data = data)
  )
  expect_error(sim_graph_from_fits(fits, data, types), "no events")
})

test_that("sim_graph rejects reserved names, missing terminal, and duplicate effects", {
  cov <- sim_covariate(function(N) rnorm(N))
  term <- sim_process("terminal", eta = 0.1, nu = 1.1)
  trans <- sim_process("transient", eta = 0.1, nu = 1.1)

  expect_error(sim_graph(time = cov, d = term), "reserved: time")
  expect_error(sim_graph(d = term, id = trans), "reserved: id")
  expect_error(sim_graph(t = cov, d = term), "reserved: t")
  expect_error(
    sim_graph(r = trans),
    "at least one sim_process\\(\"terminal\"\\)"
  )
  expect_error(
    sim_graph(
      a = cov,
      d = term,
      effects = list(sim_effect("a", "d", 1), sim_effect("a", "d", 2))
    ),
    "duplicate sim_effect"
  )
})

test_that("sim_graph rejects effects from censoring/terminal processes", {
  term <- sim_process("terminal", eta = 0.1, nu = 1.1)
  cens <- sim_process("censoring", eta = 0.1, nu = 1.1)
  trans <- sim_process("transient", eta = 0.1, nu = 1.1)

  expect_error(
    sim_graph(d = term, r = trans, effects = list(sim_effect("d", "r", 1))),
    "cannot use censoring/terminal process\\(es\\) d"
  )
  expect_error(
    sim_graph(
      d = term,
      c = cens,
      effects = list(sim_effect("c == 1", "d", 1))
    ),
    "cannot use censoring/terminal process\\(es\\) c"
  )
  # transient -> itself is allowed
  expect_no_error(
    sim_graph(d = term, r = trans, effects = list(sim_effect("r", "r", 0.1)))
  )
})

test_that("sim_graph checks sim_covariate() generator arguments", {
  term <- sim_process("terminal", eta = 0.1, nu = 1.1)

  expect_error(
    sim_graph(a = sim_covariate(function(N, zzz) rnorm(N)), d = term),
    "sim_covariate\\(\\) 'a' has argument\\(s\\) 'zzz'"
  )
  # forward reference
  expect_error(
    sim_graph(
      a = sim_covariate(function(N, b) rnorm(N)),
      b = sim_covariate(function(N) rnorm(N)),
      d = term
    ),
    "'a' has argument\\(s\\) 'b'"
  )
  expect_no_error(
    sim_graph(
      a = sim_covariate(function(N) rnorm(N)),
      b = sim_covariate(function(N, a) rnorm(N, a)),
      d = term
    )
  )
})

test_that("sim_event_graph is reproducible with seed and leaves the global RNG alone", {
  graph <- sim_graph(
    a = sim_covariate(function(N) rnorm(N)),
    c = sim_process("censoring", eta = 0.1, nu = 1.1),
    d = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(sim_effect("a", "d", 0.5))
  )

  x <- sim_event_graph(graph, n = 50, seed = 1)
  y <- sim_event_graph(graph, n = 50, seed = 1)
  z <- sim_event_graph(graph, n = 50, seed = 2)
  expect_equal(x, y)
  expect_false(isTRUE(all.equal(x, z)))

  set.seed(10)
  expected <- runif(1)
  set.seed(10)
  sim_event_graph(graph, n = 50, seed = 1)
  expect_equal(runif(1), expected)

  expect_error(sim_event_graph(graph, n = 5, seed = 1.5))
})

test_that("sim_event_graph labels events by process name, in declared order", {
  graph <- sim_graph(
    relapse = sim_process("transient", eta = 0.3, nu = 1),
    death = sim_process("terminal", eta = 0.1, nu = 1.1),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1)
  )
  data <- sim_event_graph(graph, n = 200, seed = 1)

  expect_s3_class(data$event, "factor")
  expect_equal(levels(data$event), c("relapse", "death", "censoring"))
  # Each individual's last row, and only that row, ends follow-up.
  last <- data[, .SD[.N], by = id]
  expect_true(all(last$event %in% c("death", "censoring")))
  expect_equal(sum(data$event %in% c("death", "censoring")), 200)
})

test_that("sim_event_graph labels administrative censoring as max_cens", {
  # No "censoring" process: reaching max_cens must not be recorded as the
  # terminal process.
  graph <- sim_graph(death = sim_process("terminal", eta = 0.01, nu = 1))
  data <- sim_event_graph(graph, n = 200, max_cens = 1, seed = 1)

  expect_equal(levels(data$event), c("death", "max_cens"))
  expect_true(all(data$event[data$time == 1] == "max_cens"))
  expect_true(all(data$event[data$time < 1] == "death"))
  expect_gt(sum(data$event == "max_cens"), 150)

  # Without max_cens, "max_cens" isn't a level at all.
  expect_equal(levels(sim_event_graph(graph, n = 5, seed = 1)$event), "death")
})

test_that("sim_graph rejects the reserved event labels as node names", {
  for (nm in c("event", "max_cens", "none")) {
    nodes <- list(
      sim_process("terminal", eta = 0.1, nu = 1),
      sim_process("transient", eta = 0.1, nu = 1)
    )
    names(nodes) <- c("death", nm)
    expect_error(do.call(sim_graph, nodes), "reserved")
  }
})

test_that("sim_event_graph: an effect using t switches off between events", {
  # L0 raises the death hazard before t = 2 only. Everyone has a single
  # event, so the effect has to change within the risk interval.
  graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    death = sim_process("terminal", eta = 0.2, nu = 1),
    effects = list(sim_effect("L0 * (t < 2)", "death", coef = 1))
  )
  data <- sim_event_graph(graph, n = 6000, seed = 11)
  data_split <- interval_format_data(data, time_var = TRUE, t_prime = 2)

  fit <- coxph(
    Surv(tstart, tstop, event == "death") ~ L0:strata(t_group),
    data = data_split
  )
  ci <- confint(fit)
  expect_true(ci[1, 1] <= 1 & 1 <= ci[1, 2])
  expect_true(ci[2, 1] <= 0 & 0 <= ci[2, 2])
})

test_that("sim_event_graph: a smooth effect of t matches the analytic survival", {
  # Death hazard 0.1 * exp(0.3 t) (Gompertz). Censoring has a different
  # Weibull shape, so event times are solved by bisection.
  graph <- sim_graph(
    censoring = sim_process("censoring", eta = 0.05, nu = 1.5),
    death = sim_process("terminal", eta = 0.1, nu = 1),
    effects = list(sim_effect("t", "death", coef = 0.3))
  )
  data <- sim_event_graph(graph, n = 5000, seed = 12)
  tt <- c(1, 3, 5)

  km_death <- survfit(Surv(time, event == "death") ~ 1, data = data)
  expect_equal(
    summary(km_death, times = tt)$surv,
    exp(-0.1 / 0.3 * (exp(0.3 * tt) - 1)),
    tolerance = 0.03
  )
  km_cens <- survfit(Surv(time, event == "censoring") ~ 1, data = data)
  expect_equal(
    summary(km_cens, times = tt)$surv,
    exp(-0.05 * tt^1.5),
    tolerance = 0.03
  )
})

test_that("sim_event_graph: effects using t respect max_cens", {
  graph <- sim_graph(
    death = sim_process("terminal", eta = 0.01, nu = 1),
    effects = list(sim_effect("t > 100", "death", coef = 1))
  )
  data <- sim_event_graph(graph, n = 200, max_cens = 1.234, seed = 13)

  expect_true(all(data$time <= 1.234))
  expect_true(all(data$event[data$time == 1.234] == "max_cens"))
  expect_gt(sum(data$event == "max_cens"), 150)
})

test_that("sim_event_graph validates time_step", {
  graph <- sim_graph(death = sim_process("terminal", eta = 0.1, nu = 1))
  expect_error(sim_event_graph(graph, n = 5, time_step = 0), "positive")
  expect_error(sim_event_graph(graph, n = 5, time_step = -1))
})

test_that("a cumhaz process follows its cumulative hazard curve", {
  cumhaz <- data.frame(time = c(0.5, 3, 6), hazard = c(0.5, 0.75, 2))
  true_cumhaz <- function(t) {
    stats::approx(c(0, cumhaz$time), c(0, cumhaz$hazard), xout = t)$y
  }
  graph <- sim_graph(death = sim_process("terminal", cumhaz = cumhaz))
  times <- c(0.25, 1, 5)

  data <- sim_event_graph(graph, n = 20000, seed = 1)
  surv <- vapply(times, function(x) mean(data$time > x), numeric(1))
  expect_equal(surv, exp(-true_cumhaz(times)), tolerance = 0.02)

  # Follow-up ends where the curve does:
  expect_equal(max(data$time), 6)
  expect_true(all(data$time[data$event == "max_cens"] == 6))
  expect_equal(mean(data$event == "max_cens"), exp(-2), tolerance = 0.05)
  shorter <- sim_event_graph(graph, n = 100, max_cens = 2, seed = 1)
  expect_equal(max(shorter$time), 2)

  halved <- sim_event_graph(
    graph,
    n = 20000,
    intervene = list(death = 0.5),
    seed = 1
  )
  surv <- vapply(times, function(x) mean(halved$time > x), numeric(1))
  expect_equal(surv, exp(-0.5 * true_cumhaz(times)), tolerance = 0.02)
})

test_that("a cumhaz process works with Weibull processes and time-varying effects", {
  cumhaz <- data.frame(time = c(0.5, 3, 6), hazard = c(0.5, 0.75, 2))
  graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process("terminal", cumhaz = cumhaz),
    effects = list(sim_effect("L0 * (t < 2)", "death", 1))
  )
  data <- sim_event_graph(graph, n = 10000, seed = 1)
  data_split <- interval_format_data(data, time_var = TRUE, t_prime = 2)
  fit <- coxph(
    Surv(tstart, tstop, event == "death") ~ L0:strata(t_group),
    data = data_split
  )
  expect_equal(unname(coef(fit)), c(1, 0), tolerance = 0.15)
})

test_that("sim_process validates cumhaz", {
  expect_error(
    sim_process("terminal", eta = 1, cumhaz = data.frame(time = 1, hazard = 1)),
    "not both"
  )
  expect_error(
    sim_process("terminal", cumhaz = data.frame(time = c(2, 1), hazard = 1:2)),
    "increasing"
  )
  expect_error(
    sim_process("terminal", cumhaz = data.frame(time = 1:2, hazard = 2:1)),
    "non-decreasing"
  )
  expect_error(
    sim_process("terminal", cumhaz = data.frame(time = 0:1, hazard = c(1, 2))),
    "0 at time 0"
  )
  expect_error(
    sim_process("terminal", cumhaz = data.frame(time = 1:2, hazard = 0)),
    "positive"
  )
  proc <- sim_process("terminal", cumhaz = data.frame(time = 0:1, hazard = 0:1))
  expect_equal(proc$cumhaz, data.frame(time = 1, hazard = 1))
})

test_that("sim_graph_from_fits reproduces a non-Weibull baseline hazard", {
  graph <- sim_graph(
    L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
    censoring = sim_process("censoring", eta = 0.05, nu = 1),
    death = sim_process(
      "terminal",
      cumhaz = data.frame(time = c(0.5, 3, 6), hazard = c(0.5, 0.75, 2))
    ),
    effects = list(sim_effect("L0", "death", 0.7))
  )
  observed <- sim_event_graph(graph, n = 5000, seed = 1)
  fits <- list(
    censoring = coxph(Surv(time, event == "censoring") ~ L0, data = observed),
    death = coxph(Surv(time, event == "death") ~ L0, data = observed)
  )
  types <- c(censoring = "censoring", death = "terminal")

  refit <- sim_graph_from_fits(fits, observed, types)
  expect_equal(summary(refit)$processes$baseline, c("cumhaz", "cumhaz"))

  simulated <- sim_event_graph(refit, n = 20000, seed = 2)
  probs <- c(0.25, 0.5, 0.75)
  expect_equal(
    unname(quantile(simulated$time, probs)),
    unname(quantile(observed$time, probs)),
    tolerance = 0.1
  )
  expect_lte(max(simulated$time), max(observed$time))
})
