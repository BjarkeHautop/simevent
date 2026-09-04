test_that("simEventObj simulates data consistent with the fitted Cox models", {
  set.seed(926489)
  # The observed data
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  data <- simCRdata(N = 5000, beta = beta)
  old_vars <- data[, c("L0", "A0")]

  # Fit Cox Models
  cox1 <- survival::coxph(
    survival::Surv(Time, Delta == 1) ~ L0 + A0,
    data = data
  )
  cox2 <- survival::coxph(
    survival::Surv(Time, Delta == 2) ~ L0 + A0,
    data = data
  )

  # Create Object
  cox_fits <- list("D" = cox1, "L" = cox2)
  class(cox_fits) <- "simevent"

  # Equip with predict2 method. simEventObj() calls `predict2()` unqualified
  # from within the package namespace, so the generic and method must be
  # made visible on the global search path (not just local to this test)
  # for the lookup to succeed -- hence `<<-` and cleanup via on.exit().
  predict2 <<- function(obj, ...) {
    UseMethod("predict2")
  }
  on.exit(rm(predict2, predict2.simevent, envir = .GlobalEnv), add = TRUE)
  predict2.simevent <<- function(obj, sim_data) {
    # Base hazards
    basehazz_list <- lapply(obj, function(model) {
      basehaz(model, centered = FALSE)
    })

    # Individual specific term
    cox_term <- lapply(obj, function(model) {
      exp(stats::predict(
        model,
        newdata = sim_data,
        type = "lp",
        reference = "zero"
      ))
    })

    # Chf
    chf_list <- lapply(seq_along(obj), function(j) {
      cox_term[[j]] %*% t(basehazz_list[[j]][["hazard"]])
    })
    chf <- array(dim = c(c(dim(chf_list[[1]])), length(obj)))
    for (j in seq_along(obj)) {
      chf[,, j] <- chf_list[[j]]
    }

    # Return list
    list(time = basehazz_list[[1]][["time"]], chf = chf)
  }

  # Simulate new data
  new_data <- simEventObj(5000, cox_fits, old_vars = old_vars)

  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "N0", "N1") %in%
      names(new_data)
  ))
  expect_equal(nrow(new_data), 5000)

  # A handful of individuals draw a time beyond the observed follow-up
  # (the cumulative hazard is only known up to the last observed jump);
  # these get Time = Inf, Delta = 0 ("no event"), which coxph cannot
  # handle directly, so we drop them (as one naturally would in practice).
  new_data_finite <- new_data[is.finite(Time)]
  expect_true(nrow(new_data_finite) >= 0.99 * nrow(new_data))

  # Check whether new data corresponds to the old data
  coxfit1 <- coxph(Surv(Time, Delta == 1) ~ L0 + A0, data = new_data_finite)
  coxfit2 <- coxph(Surv(Time, Delta == 2) ~ L0 + A0, data = new_data_finite)

  # Compute confidence intervals
  ci1 <- confint(cox1)
  coef1 <- coxfit1$coefficients

  ci2 <- confint(cox2)
  coef2 <- coxfit2$coefficients

  # Compare confidence intervals and true values
  expect_true(all(coef1 >= ci1[, 1] & coef1 <= ci1[, 2]))
  expect_true(all(coef2 >= ci2[, 1] & coef2 <= ci2[, 2]))
})

test_that("simEventObj supports custom event_names", {
  set.seed(10)
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  data <- simCRdata(N = 300, beta = beta)
  old_vars <- data[, c("L0", "A0")]

  cox1 <- survival::coxph(
    survival::Surv(Time, Delta == 1) ~ L0 + A0,
    data = data
  )
  cox_fits <- list("D" = cox1)
  class(cox_fits) <- "simevent"

  predict2 <<- function(obj, ...) UseMethod("predict2")
  on.exit(rm(predict2, predict2.simevent, envir = .GlobalEnv), add = TRUE)
  predict2.simevent <<- function(obj, sim_data) {
    basehazz_list <- lapply(obj, function(model) {
      basehaz(model, centered = FALSE)
    })
    cox_term <- lapply(obj, function(model) {
      exp(stats::predict(
        model,
        newdata = sim_data,
        type = "lp",
        reference = "zero"
      ))
    })
    chf_list <- lapply(seq_along(obj), function(j) {
      cox_term[[j]] %*% t(basehazz_list[[j]][["hazard"]])
    })
    chf <- array(dim = c(dim(chf_list[[1]]), length(obj)))
    for (j in seq_along(obj)) {
      chf[,, j] <- chf_list[[j]]
    }
    list(time = basehazz_list[[1]][["time"]], chf = chf)
  }

  new_data <- simEventObj(
    100,
    cox_fits,
    old_vars = old_vars,
    event_names = "myEvent"
  )
  expect_true("myEvent" %in% names(new_data))
  expect_false("N0" %in% names(new_data))
})

test_that("simEventObj supports useOldVars = TRUE (deterministic covariates)", {
  set.seed(11)
  beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
  data <- simCRdata(N = 250, beta = beta)
  old_vars <- data[, c("L0", "A0")]

  cox1 <- survival::coxph(
    survival::Surv(Time, Delta == 1) ~ L0 + A0,
    data = data
  )
  cox_fits <- list("D" = cox1)
  class(cox_fits) <- "simevent"

  predict2 <<- function(obj, ...) UseMethod("predict2")
  on.exit(rm(predict2, predict2.simevent, envir = .GlobalEnv), add = TRUE)
  predict2.simevent <<- function(obj, sim_data) {
    basehazz_list <- lapply(obj, function(model) {
      basehaz(model, centered = FALSE)
    })
    cox_term <- lapply(obj, function(model) {
      exp(stats::predict(
        model,
        newdata = sim_data,
        type = "lp",
        reference = "zero"
      ))
    })
    chf_list <- lapply(seq_along(obj), function(j) {
      cox_term[[j]] %*% t(basehazz_list[[j]][["hazard"]])
    })
    chf <- array(dim = c(dim(chf_list[[1]]), length(obj)))
    for (j in seq_along(obj)) {
      chf[,, j] <- chf_list[[j]]
    }
    list(time = basehazz_list[[1]][["time"]], chf = chf)
  }

  new_data <- simEventObj(
    nrow(old_vars),
    cox_fits,
    old_vars = old_vars,
    useOldVars = TRUE
  )
  expect_equal(nrow(new_data), nrow(old_vars))
  expect_equal(sort(new_data$L0), sort(old_vars$L0))
  expect_equal(sort(new_data$A0), sort(old_vars$A0))
})
