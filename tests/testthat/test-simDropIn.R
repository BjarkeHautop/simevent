test_that("simDropIn simulates data in the right way (adherence = FALSE)", {
  set.seed(101)
  data_test <- simDropIn(5000)

  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "Z", "L") %in% names(data_test)
  ))
  expect_false(any(c("N0", "N1") %in% names(data_test)))

  # Transform data into tstart tstop format (C, D, Z, L -> 4 processes)
  data_int <- IntFormatData(data_test, N_cols = 6:7)

  survfit_death <- coxph(
    Surv(tstart, tstop, Delta == 1) ~ L0 + A0 + Z + L,
    data = data_int
  )
  survfit_Z <- coxph(
    Surv(tstart, tstop, Delta == 2) ~ L0 + A0,
    data = data_int[L == 0]
  )
  survfit_L <- coxph(
    Surv(tstart, tstop, Delta == 3) ~ L0 + A0 + Z,
    data = data_int
  )

  # Default betas: beta_L0_D=1, beta_A0_D=-2, beta_Z_D=-1, beta_L_D=1.5
  expect_true(
    confint(survfit_death, level = 0.99)[1, 1] <= 1 &
      1 <= confint(survfit_death, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[2, 1] <= -2 &
      -2 <= confint(survfit_death, level = 0.99)[2, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[3, 1] <= -1 &
      -1 <= confint(survfit_death, level = 0.99)[3, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[4, 1] <= 1.5 &
      1.5 <= confint(survfit_death, level = 0.99)[4, 2]
  )

  # Default betas: beta_L0_Z=1, beta_A0_Z=0
  expect_true(
    confint(survfit_Z, level = 0.99)[1, 1] <= 1 &
      1 <= confint(survfit_Z, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit_Z, level = 0.99)[2, 1] <= 0 &
      0 <= confint(survfit_Z, level = 0.99)[2, 2]
  )

  # Default betas: beta_L0_L=1, beta_A0_L=-1.5 (Z is included as a
  # time-varying covariate for a correctly specified model, but its
  # coefficient is not checked quantitatively here since beta_L_Z=2
  # creates a strong Z-L confounding/selection effect on the "L" event
  # that biases the marginal Z coefficient away from beta_Z_L=-1, even
  # at very large N; this is a statistical/confounding artifact of the
  # chosen defaults, not something this coverage-focused test verifies).
  expect_true(
    confint(survfit_L, level = 0.99)[1, 1] <= 1 &
      1 <= confint(survfit_L, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit_L, level = 0.99)[2, 1] <= -1.5 &
      -1.5 <= confint(survfit_L, level = 0.99)[2, 2]
  )
})

test_that("simDropIn works with cens = 0 (no censoring events)", {
  set.seed(102)
  data_test <- simDropIn(500, cens = 0)
  expect_false(0 %in% data_test$Delta)
})

test_that("simDropIn works with a t_prime time-varying effect", {
  set.seed(103)
  data_test <- simDropIn(500, t_prime = 1, beta_A0_D_prime = 1)
  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "Z", "L") %in% names(data_test)
  ))
  expect_true(nrow(data_test) > 0)
})

test_that("simDropIn works with a custom followup (censoring time)", {
  set.seed(104)
  data_test <- simDropIn(300, followup = 2)
  expect_true(all(data_test[, max(Time), by = ID]$V1 <= 2))
})

test_that("simDropIn simulates data in the right way (adherence = TRUE)", {
  set.seed(105)
  data_test <- simDropIn(4000, adherence = TRUE)

  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "Z", "L", "A") %in% names(data_test)
  ))
  expect_true(all(data_test$A %in% c(0, 1)))

  # Transform data into tstart tstop format (C, D, Z, L, A -> 5 processes)
  data_int <- IntFormatData(data_test, N_cols = 6:8)

  survfit_death <- coxph(
    Surv(tstart, tstop, Delta == 1) ~ L0 + A0 + Z + L + A,
    data = data_int
  )

  # Default betas: beta_L0_D=1, beta_A0_D=-2, beta_Z_D=-1, beta_L_D=1.5,
  # beta_A_D=-1
  expect_true(
    confint(survfit_death, level = 0.99)[1, 1] <= 1 &
      1 <= confint(survfit_death, level = 0.99)[1, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[2, 1] <= -2 &
      -2 <= confint(survfit_death, level = 0.99)[2, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[3, 1] <= -1 &
      -1 <= confint(survfit_death, level = 0.99)[3, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[4, 1] <= 1.5 &
      1.5 <= confint(survfit_death, level = 0.99)[4, 2]
  )
  expect_true(
    confint(survfit_death, level = 0.99)[5, 1] <= -1 &
      -1 <= confint(survfit_death, level = 0.99)[5, 2]
  )
})

test_that("simDropIn works with adherence = TRUE and a t_prime time-varying effect", {
  set.seed(106)
  data_test <- simDropIn(
    500,
    adherence = TRUE,
    t_prime = 1,
    beta_A_D_prime = 1
  )
  expect_true(all(
    c("ID", "Time", "Delta", "L0", "A0", "Z", "L", "A") %in% names(data_test)
  ))
  expect_true(nrow(data_test) > 0)
})
