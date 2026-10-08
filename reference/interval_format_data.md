# Convert Simulated Event Data to Start-Stop Format

Converts
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
output to start-stop format for `coxph(Surv(tstart, tstop, ...))`.

## Usage

``` r
interval_format_data(
  data,
  proc_cols = character(0),
  mark_cols = character(0),
  time_var = FALSE,
  t_prime = NULL
)
```

## Arguments

- data:

  Output of
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md).

- proc_cols:

  Character vector. `"transient"`-process columns to use as time-varying
  covariates: each row then holds the count *before* its event.

- mark_cols:

  Character vector.
  [`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)
  columns to use as time-varying covariates: each row then holds the
  value *before* its event, i.e. the one in force during its interval,
  taken from the `<name>_0` baseline column for the first row.

- time_var:

  Logical. Split intervals at `t_prime`? Default `FALSE`.

- t_prime:

  Numeric. Split time. Adds a `t_group` column (1 before, 2 after), so
  an effect can differ between the periods (see Examples). The first
  half of a split interval has `event = "none"`.

## Value

`data` with added columns `tstart`, `tstop` and `k` (event number).

## See also

[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)

## Examples

``` r
model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1),
  effects = list(sim_effect("relapse", "death", 0.5))
)
data <- sim_events(model, n = 500)
data_int <- interval_format_data(data, proc_cols = "relapse")
head(data_int)
#>       id      time     event        L0 relapse     k   tstart     tstop
#>    <int>     <num>    <fctr>     <num>   <num> <int>    <num>     <num>
#> 1:     1 1.6988933 censoring 0.3152944       0     1 0.000000 1.6988933
#> 2:     2 4.9282638   relapse 0.1121613       0     1 0.000000 4.9282638
#> 3:     2 6.3790613 censoring 0.1121613       1     2 4.928264 6.3790613
#> 4:     3 4.4633263     death 0.6211252       0     1 0.000000 4.4633263
#> 5:     4 0.1193703     death 0.6278351       0     1 0.000000 0.1193703
#> 6:     5 1.3924952   relapse 0.2475538       0     1 0.000000 1.3924952

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
#>             coef exp(coef) se(coef)      z        p
#> L0      -0.11642   0.89010  0.21433 -0.543    0.587
#> relapse  0.52509   1.69061  0.07353  7.141 9.23e-13
#> 
#> Likelihood ratio test=47.5  on 2 df, p=4.848e-11
#> n= 854, number of events= 272 

# Splitting at t_prime tests whether an effect changes over time. Here L0
# raises the death hazard before time 2 only:
model_tv <- sim_model(
  L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  death = sim_process("terminal", eta = 0.2, nu = 1),
  effects = list(sim_effect("L0 * (t < 2)", "death", coef = 1))
)
data_tv <- sim_events(model_tv, n = 2000)
data_split <- interval_format_data(data_tv, time_var = TRUE, t_prime = 2)

# One L0 coefficient per period: about 1 before t_prime, about 0 after.
survival::coxph(
  survival::Surv(tstart, tstop, event == "death") ~ L0:strata(t_group),
  data = data_split
)
#> Call:
#> survival::coxph(formula = survival::Surv(tstart, tstop, event == 
#>     "death") ~ L0:strata(t_group), data = data_split)
#> 
#>                                coef exp(coef) se(coef)      z      p
#> L0:strata(t_group)t_group=1 1.08781   2.96775  0.06848 15.884 <2e-16
#> L0:strata(t_group)t_group=2 0.05288   1.05430  0.06742  0.784  0.433
#> 
#> Likelihood ratio test=273.7  on 2 df, p=< 2.2e-16
#> n= 3022, number of events= 2000 
```
