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
    c("id", "time", "delta", "region", "region2", "region3")
  )
  expect_true(all(data$region2 %in% c(0, 1)))

  fit <- coxph(Surv(time, delta == 1) ~ factor(region), data = data)
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

  expect_setequal(names(data), c("id", "time", "delta"))
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

  expect_setequal(names(data), c("id", "time", "delta", "L0"))

  fit_death <- coxph(Surv(time, delta == 1) ~ L0, data = data)
  expect_true(confint(fit_death)[1, 1] <= 1.5 & 1.5 <= confint(fit_death)[1, 2])

  fit_cens <- coxph(Surv(time, delta == 0) ~ L0, data = data)
  expect_true(confint(fit_cens)[1, 1] <= -0.5 & -0.5 <= confint(fit_cens)[1, 2])
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

  expect_setequal(names(data), c("id", "time", "delta", "relapse"))
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
  expect_true(mean(data_high$delta == 1) > mean(data_base$delta == 1))

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
  observed_data <- simCRdata(N = 2000, beta = beta)

  fits <- list(
    censoring = coxph(Surv(Time, Delta == 0) ~ L0 + A0, data = observed_data),
    cause1 = coxph(Surv(Time, Delta == 1) ~ L0 + A0, data = observed_data),
    cause2 = coxph(Surv(Time, Delta == 2) ~ L0 + A0, data = observed_data)
  )
  types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")

  graph <- sim_graph_from_fits(fits, observed_data, types)
  expect_s3_class(graph, "sim_graph")

  new_data <- sim_event_graph(graph, n = 5000)
  expect_setequal(names(new_data), c("id", "time", "delta", "L0", "A0"))

  observed_props <- prop.table(table(observed_data$Delta))
  simulated_props <- prop.table(table(new_data$delta))
  expect_equal(
    as.numeric(observed_props),
    as.numeric(simulated_props[names(observed_props)]),
    tolerance = 0.05
  )
})

test_that("sim_graph_from_fits builds sim_derived() dummies for a factor covariate", {
  set.seed(1405)
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  observed_data <- simCRdata(N = 3000, beta = beta)
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
  expect_named(graph$covariates, c("L0", "region", "regionb", "regionc"))

  new_data <- sim_event_graph(graph, n = 3000)
  expect_setequal(
    names(new_data),
    c("id", "time", "delta", "L0", "region", "regionb", "regionc")
  )
  expect_true(all(new_data$region %in% 1:3))
  expect_equal(new_data$regionb, as.numeric(new_data$region == 2))
  expect_equal(new_data$regionc, as.numeric(new_data$region == 3))
})

test_that("sim_graph_from_fits validates types/fits/limits", {
  fit <- coxph(Surv(Time, Delta == 0) ~ L0, data = simSurvData(100))

  expect_error(
    sim_graph_from_fits(list(a = fit), simSurvData(100), c(b = "censoring")),
    "permutation"
  )
  expect_error(
    sim_graph_from_fits(list(a = fit), simSurvData(100), c(a = "bogus")),
    "subset"
  )
  expect_error(
    sim_graph_from_fits(
      list(a = "not a fit"),
      simSurvData(100),
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
    censoring = coxph(Surv(time, delta == 0) ~ L0, data = observed_data),
    death = coxph(Surv(time, delta == 1) ~ L0 + relapse, data = observed_data),
    relapse = coxph(Surv(time, delta == 2) ~ 1, data = observed_data)
  )
  types <- c(censoring = "censoring", death = "terminal", relapse = "transient")

  graph <- sim_graph_from_fits(fits, observed_data, types)

  # relapse must be a process node, not a baseline covariate rebuilt from
  # its (meaningless, since it's a running count, not a fixed baseline
  # value) marginal mean/sd.
  expect_named(graph$covariates, "L0")
  expect_named(graph$processes, c("censoring", "death", "relapse"))

  effect_pairs <- vapply(
    graph$effects,
    function(e) paste(e$from, e$to, sep = "->"),
    character(1)
  )
  expect_true("relapse->death" %in% effect_pairs)

  new_data <- sim_event_graph(graph, n = 100)
  expect_setequal(names(new_data), c("id", "time", "delta", "L0", "relapse"))
})
