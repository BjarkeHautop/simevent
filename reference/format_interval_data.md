# Convert Simulated Event Data to Start-Stop Format

Converts
[`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)
output to start-stop format for `coxph(Surv(tstart, tstop, ...))`.

## Usage

``` r
format_interval_data(
  data,
  proc_cols = character(0),
  mark_cols = character(0),
  t_prime = NULL
)
```

## Arguments

- data:

  Output of
  [`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md).

- proc_cols:

  Character vector. `"transient"`-process columns to use as time-varying
  covariates: each row then holds the count *before* its event.

- mark_cols:

  Character vector.
  [`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)
  columns to use as time-varying covariates: each row then holds the
  value *before* its event, i.e. the one in force during its interval,
  taken from the `<name>_0` baseline column for the first row.

- t_prime:

  Numeric. Optional time to split intervals at. Adds a `t_group` column
  (1 before, 2 after), so an effect can differ between the periods (see
  Examples). The first half of a split interval has `event = "none"`.

## Value

`data` with added columns `tstart`, `tstop` and `k` (event number).

## See also

[`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)

## Examples

``` r
model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1),
  effects = list(sim_effect(death ~ relapse, coef = 0.5))
)
data <- simulate_events(model, n = 500)
data_int <- format_interval_data(data, proc_cols = "relapse")
head(data_int)
#> Key: <id>
#>       id      time   event        L0 relapse     k   tstart     tstop
#>    <int>     <num>  <fctr>     <num>   <num> <int>    <num>     <num>
#> 1:     1 1.8635429 relapse 0.2862210       0     1 0.000000 1.8635429
#> 2:     1 2.8085723   death 0.2862210       1     2 1.863543 2.8085723
#> 3:     2 4.8449127 relapse 0.8720524       0     1 0.000000 4.8449127
#> 4:     2 5.0110369 relapse 0.8720524       1     2 4.844913 5.0110369
#> 5:     2 5.2628444   death 0.8720524       2     3 5.011037 5.2628444
#> 6:     3 0.6523381   death 0.4353905       0     1 0.000000 0.6523381

# relapse is now the cumulative count *before* each row's event, so it can
# be used as a time-varying covariate:
survival::coxph(
  survival::Surv(tstart, tstop, event == "death") ~ L0 + relapse,
  data = data_int
)
#> Call:
#> survival::coxph(formula = survival::Surv(tstart, tstop, event == 
#>     "death") ~ L0 + relapse, data = data_int)
#> 
#>             coef exp(coef) se(coef)      z       p
#> L0      -0.00862   0.99142  0.20968 -0.041   0.967
#> relapse  0.40382   1.49754  0.06946  5.814 6.1e-09
#> 
#> Likelihood ratio test=31.45  on 2 df, p=1.485e-07
#> n= 848, number of events= 302 

# Splitting at t_prime tests whether an effect changes over time. Here L0
# raises the death hazard before time 2 only:
model_tv <- sim_model(
  L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  death = sim_process("terminal", eta = 0.2, nu = 1),
  effects = list(sim_effect(death ~ L0 * (t < 2), coef = 1))
)
data_tv <- simulate_events(model_tv, n = 2000)
data_split <- format_interval_data(data_tv, t_prime = 2)

# One L0 coefficient per period: about 1 before t_prime, about 0 after.
survival::coxph(
  survival::Surv(tstart, tstop, event == "death") ~ L0:strata(t_group),
  data = data_split
)
#> Call:
#> survival::coxph(formula = survival::Surv(tstart, tstop, event == 
#>     "death") ~ L0:strata(t_group), data = data_split)
#> 
#>                                 coef exp(coef) se(coef)      z      p
#> L0:strata(t_group)t_group=1  0.91827   2.50496  0.06552 14.014 <2e-16
#> L0:strata(t_group)t_group=2 -0.08126   0.92196  0.06814 -1.192  0.233
#> 
#> Likelihood ratio test=209  on 2 df, p=< 2.2e-16
#> n= 2974, number of events= 2000 
```
