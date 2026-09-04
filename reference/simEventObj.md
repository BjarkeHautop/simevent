# Simulate Survival and Competing Risk Data Based on a General Model

The `simEventObj` function simulates survival or competing risk data for
a cohort of individuals based on a general model with a `predict2`
method. The function is useful for simulating additional data under the
same distribution as an original data set. The procedure consists of
fitting a model, such as a random forest or Cox Proportional Hazards
model on an original data set. Next the model is equipped with a
`predict2` method, and passed as an argument to the `simEventObj`
function, which simulates new data using the `predict2` method. The
method should output the cumulative hazard array and the jump times of
the cumulative hazard. Simulation proceeds by sampling from the uniform
distribution and obtaining event times using the inverse of the
cumulative hazard function(s).

## Usage

``` r
simEventObj(N, obj, event_names = NULL, old_vars = NULL, useOldVars = FALSE)
```

## Arguments

- N:

  Integer. The number of individuals to simulate.

- obj:

  An object of class `simevent`. The object should have a predict2
  method. The method should return a list containing `chf` and `time`.
  `chf` should be an array of dimension Individuals x Times x Events.
  The array should contain the cumulative hazard values for each
  individual, at each time for each event. `time` should be a vector of
  times where the cumulative hazard function jumps.

- event_names:

  A character vector. Containing the names of the various processes. The
  argument is optional. By default events will be named `N0`, `N1`, ....

- old_vars:

  A named matrix containing the old covariates. New covariates will be
  simulated by drawing rows from the old covariates with replacement.

- useOldVars:

  Logical. If `TRUE` the simulations use `old_vars` directly, rather
  than draw rows from the matrix.

## Value

A `data.table` with one row per event per individual containing:

- `ID` — Individual identifier.

- `Time` — Event time.

- `Delta` — Event type indicator.

- Baseline covariates.

- Columns for each event type indicating cumulative event counts.

## Details

The function simulates individual event histories by:

1.  Sampling initial baseline covariates by resampling observed values.

2.  Extracting cumulative hazard functions from the object.

3.  Iteratively sampling event times.

4.  Updating covariate histories and event counts.

5.  Stopping simulation per individual after a terminal event or maximum
    events reached.

## Examples

``` r
# Fit a Cox model and equip it with a predict2 method
data_obs <- simCRdata(N = 200)
cox_fit <- survival::coxph(survival::Surv(Time, Delta == 1) ~ L0 + A0, data = data_obs)

predict2 <- function(obj, ...) UseMethod("predict2")
predict2.coxph <- function(obj, sim_data, ...) {
  preds <- survival::survfit(obj, newdata = sim_data)
  # preds$cumhaz is a times x individuals matrix; reshape to individuals x times x events
  chf <- array(t(preds$cumhaz), dim = c(nrow(sim_data), length(preds$time), 1))
  list(time = preds$time, chf = chf)
}

old_vars <- data_obs[, c("L0", "A0")]
new_data <- simEventObj(100, cox_fit, old_vars = old_vars)
#> Error in predict2(obj, sim_data): could not find function "predict2"
```
