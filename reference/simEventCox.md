# Simulate Event History Data Based on Cox Models

Simulates recurrent and terminal event data for a cohort of individuals
based on a list of fitted Cox proportional hazards models. Each event
type is governed by its own model, and simulation proceeds by
iteratively sampling event times until a terminal event occurs.

## Usage

``` r
simEventCox(
  N,
  cox_fits,
  old_vars = NULL,
  useOldVars = FALSE,
  n_event_max = c(1, 1),
  term_events = 1,
  intervention1 = NULL,
  intervention2 = NULL,
  at_risk = NULL
)
```

## Arguments

- N:

  Integer. The number of individuals to simulate.

- cox_fits:

  A named list of fitted Cox proportional hazards models (`coxph`
  objects), one for each event type. The names are used as event type
  labels.

- old_vars:

  A named matrix containing the old covariates. New covariates will be
  simulated by drawing rows from the old covariates with replacement.

- useOldVars:

  Logical. If `TRUE` the simulations use `old_vars` directly, rather
  than draw rows from the matrix.

- n_event_max:

  Integer vector. Maximum number of times each event type can occur per
  individual.

- term_events:

  Integer or integer vector. Indices of event types that are terminal,
  i.e., events that stop further simulation for an individual.

- intervention1:

  Optional function. Takes arguments `(j, sim_matrix)` and returns an
  updated simulation matrix. Used to modify covariates dynamically at
  each event iteration.

- intervention2:

  Optional function. Takes arguments `(j, H_j)` and returns a modified
  baseline cumulative hazard vector for event type `j`. Allows dynamic
  hazard modification. The function
  `intervention2 <- function(j, basehaz) if(j ==2) 1.15 * basehaz else basehaz`
  performs an intervention where the baseline hazard of process 2 is
  multiplied by 1.15.

- at_risk:

  Function. Function determining if an individual is at risk for each
  event type, given their current event counts. Takes a numeric vector
  of event counts and returns a binary vector. Default returns 1 for all
  events.

## Value

A `data.table` with one row per event per individual containing:

- `ID` — Individual identifier.

- `Time` — Event time.

- `Delta` — Event type indicator.

- Baseline covariates

- Columns for each event type indicating cumulative event counts.

## Details

The function simulates individual event histories by:

1.  Sampling initial baseline covariates by resampling observed values.

2.  Extracting baseline cumulative hazard functions from the Cox models.

3.  Iteratively sampling event times.

4.  Updating covariate histories and event counts.

5.  Stopping simulation per individual after a terminal event or maximum
    events reached.

## Examples

``` r
# The observed data
data_obs <- simDisease(N = 1000)
data_obs <- IntFormatData(data_obs, N_cols = 6)

# Fit Cox models
cox_death <- survival::coxph(survival::Surv(tstart, tstop, Delta == 1)
~ L0 + A0 + L, data = data_obs)
cox_Disease <- survival::coxph(survival::Surv(tstart, tstop, Delta == 2)
~ L0 + A0, data = data_obs[L == 0])

# Then simulate new data:
cox_fits <- list("D" = cox_death, "L" = cox_Disease)
old_vars <- data_obs[, c("L0", "A0")]
new_data <- simEventCox(100, cox_fits = cox_fits, old_vars = old_vars)
```
