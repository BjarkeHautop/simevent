test_that("alphaSim returns proportions for the Disease setting", {
  set.seed(400)
  res <- alphaSim(
    N = 300,
    eta = rep(0.1, 3),
    nu = rep(1.1, 3),
    alpha = 0.5,
    setting = "Disease"
  )
  expect_named(res, c("effectDeath", "effectSetting"))
  expect_true(res$effectDeath >= 0 && res$effectDeath <= 1)
  expect_true(res$effectSetting >= 0 && res$effectSetting <= 1)
})

test_that("alphaSim returns proportions for the Drop In setting", {
  set.seed(401)
  res <- alphaSim(N = 300, setting = "Drop In", beta_A0_Z = 1)
  expect_named(res, c("effectDeath", "effectSetting"))
  expect_true(res$effectDeath >= 0 && res$effectDeath <= 1)
  expect_true(res$effectSetting >= 0 && res$effectSetting <= 1)
})

test_that("alphaSim returns proportions for the Treatment setting", {
  set.seed(402)
  res <- alphaSim(N = 300, setting = "Treatment")
  expect_named(res, c("effectDeath", "effectSetting"))
  expect_true(res$effectDeath >= 0 && res$effectDeath <= 1)
  expect_true(res$effectSetting >= 0 && res$effectSetting <= 1)
})

test_that("alphaSim returns proportions for the Statin setting", {
  set.seed(403)
  res <- alphaSim(
    N = 300,
    eta = rep(0.1, 12),
    nu = rep(1.1, 12),
    setting = "Statin",
    max_events = 50
  )
  expect_named(res, c("effectDeath", "effectSetting"))
  expect_true(res$effectDeath >= 0 && res$effectDeath <= 1)
  expect_true(res$effectSetting >= 0 && res$effectSetting <= 1)
})

test_that("alphaSim can return raw simulated data instead of proportions", {
  set.seed(404)
  data_test <- alphaSim(
    N = 50,
    eta = rep(0.1, 3),
    nu = rep(1.1, 3),
    setting = "Disease",
    return_data = TRUE
  )
  expect_s3_class(data_test, "data.table")
  expect_true(all(c("ID", "Time", "Delta") %in% names(data_test)))
})

test_that("alphaSim can return years-lost instead of proportions", {
  set.seed(405)
  res <- alphaSim(
    N = 200,
    eta = rep(0.1, 3),
    nu = rep(1.1, 3),
    setting = "Disease",
    years_lost = TRUE,
    tau = 5
  )
  expect_named(res, c("effectDeath", "effectSetting"))
  expect_true(res$effectDeath >= 0)
  expect_true(res$effectSetting >= 0)
})

test_that("alphaSim errors for an unrecognized setting", {
  set.seed(406)
  expect_error(
    alphaSim(N = 10, setting = "Not A Setting"),
    "Setting must be either Disease, Drop In, Treatment or Statin"
  )
})

test_that("alphaSim errors when eta has the wrong length for the setting", {
  set.seed(407)
  expect_error(
    alphaSim(N = 10, setting = "Disease", eta = rep(0.1, 4)),
    "eta and nu must be of length 3"
  )
  expect_error(
    alphaSim(N = 10, setting = "Drop In", eta = rep(0.1, 3)),
    "eta and nu must be of length 4"
  )
  expect_error(
    alphaSim(N = 10, setting = "Treatment", eta = rep(0.1, 3)),
    "eta and nu must be of length 4"
  )
  expect_error(
    alphaSim(
      N = 10,
      setting = "Statin",
      eta = rep(0.1, 3),
      nu = rep(1.1, 3)
    ),
    "eta and nu must be of length 12"
  )
})
