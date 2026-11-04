library(survival)

# Expects every coefficient's 95% confidence interval in `fit` to cover its
# true value in `truth` (in the order of coef(fit)).
expect_ci_covers <- function(fit, truth) {
  ci <- stats::confint(fit)
  covered <- ci[, 1] <= truth & truth <= ci[, 2]
  expect_true(
    all(covered),
    label = paste0(
      "CI covers truth for ",
      paste(rownames(ci)[!covered], collapse = ", ")
    )
  )
}

# One row per id of simulate_events() output: end of follow-up and whether it
# ended in death, as a base for survival::tmerge().
follow_up <- function(data) {
  last <- data[!duplicated(data$id, fromLast = TRUE), ]
  data.frame(
    id = last$id,
    futime = last$time,
    death = as.integer(last$event == "death")
  )
}

# Competing-risks data with censoring and two causes, affected by L0 and A0.
sim_cr_data <- function(n) {
  model <- sim_model(
    L0 = sim_covariate(function(N) runif(N)),
    A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
    censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
    cause1 = sim_process("terminal", eta = 0.1, nu = 1.1),
    cause2 = sim_process("terminal", eta = 0.1, nu = 1.1),
    effects = list(
      sim_effect(censoring ~ L0 + A0, coef = c(0.5, -1)),
      sim_effect(cause1 ~ L0 + A0, coef = c(-0.5, 0.5)),
      sim_effect(cause2 ~ A0, coef = 0.5)
    )
  )
  simulate_events(model, n = n)
}
