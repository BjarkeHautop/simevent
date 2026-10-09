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

# One row per id of sim_events() output: end of follow-up and whether it
# ended in death, as a base for survival::tmerge().
follow_up <- function(data) {
  last <- data[!duplicated(data$id, fromLast = TRUE), ]
  data.frame(
    id = last$id,
    futime = last$time,
    death = as.integer(last$event == "death")
  )
}
