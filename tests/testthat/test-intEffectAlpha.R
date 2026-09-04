test_that("intEffectAlpha returns proportions for the Drop In setting", {
  set.seed(500)
  res <- intEffectAlpha(
    N = 300,
    alpha = 0.7,
    tau = 5,
    years_lost = FALSE,
    a0 = 1,
    setting = "Drop In",
    plot = FALSE
  )
  expect_named(res, c("effect_2", "effect_death"))
  expect_true(res$effect_2 >= 0 && res$effect_2 <= 1)
  expect_true(res$effect_death >= 0 && res$effect_death <= 1)
})

test_that("intEffectAlpha returns proportions for the Disease setting", {
  set.seed(501)
  res <- intEffectAlpha(
    N = 300,
    setting = "Disease",
    eta = rep(0.1, 3),
    nu = rep(1.1, 3),
    plot = FALSE
  )
  expect_named(res, c("effect_2", "effect_death"))
  expect_true(res$effect_2 >= 0 && res$effect_2 <= 1)
  expect_true(res$effect_death >= 0 && res$effect_death <= 1)
})

test_that("intEffectAlpha returns proportions for the Treatment setting", {
  set.seed(502)
  res <- intEffectAlpha(N = 200, setting = "Treatment", plot = FALSE)
  expect_named(res, c("effect_2", "effect_death"))
  expect_true(res$effect_2 >= 0 && res$effect_2 <= 1)
  expect_true(res$effect_death >= 0 && res$effect_death <= 1)
})

test_that("intEffectAlpha can return years-lost for Disease and Treatment", {
  set.seed(503)
  res_disease <- intEffectAlpha(
    N = 100,
    setting = "Disease",
    eta = rep(0.1, 3),
    nu = rep(1.1, 3),
    years_lost = TRUE,
    plot = FALSE
  )
  expect_true(res_disease$effect_2 >= 0)
  expect_true(res_disease$effect_death >= 0)

  set.seed(504)
  res_treat <- intEffectAlpha(
    N = 100,
    setting = "Treatment",
    years_lost = TRUE,
    plot = FALSE
  )
  expect_true(res_treat$effect_2 >= 0)
  expect_true(res_treat$effect_death >= 0)
})

test_that("intEffectAlpha plots when plot = TRUE (default)", {
  set.seed(505)
  res <- intEffectAlpha(N = 50, setting = "Drop In")
  expect_named(res, c("effect_2", "effect_death"))
})

test_that("intEffectAlpha errors for settings not allowed (e.g. Statin)", {
  set.seed(506)
  expect_error(
    intEffectAlpha(
      N = 10,
      eta = rep(0.1, 12),
      nu = rep(1.1, 12),
      setting = "Statin"
    ),
    "Setting must be either Disease, Drop In or Treatment"
  )
})
