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

- t_prime:

  Numeric. Optional time to split intervals at. Adds a `t_group` column
  (1 before, 2 after), so an effect can differ between the periods (see
  Examples). The first half of a split interval has `event = "none"`.

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
  effects = list(sim_effect(death ~ relapse, coef = 0.5))
)
data <- sim_events(model, n = 500)
data_int <- interval_format_data(data, proc_cols = "relapse")
head(data_int)
#> Key: <id>
#>       id     time     event        L0 relapse     k   tstart    tstop
#>    <int>    <num>    <fctr>     <num>   <num> <int>    <num>    <num>
#> 1:     1 2.582850     death 0.9409763       0     1 0.000000 2.582850
#> 2:     2 3.009249     death 0.6166710       0     1 0.000000 3.009249
#> 3:     3 5.325178   relapse 0.3195034       0     1 0.000000 5.325178
#> 4:     3 5.413429   relapse 0.3195034       1     2 5.325178 5.413429
#> 5:     3 5.470893   relapse 0.3195034       2     3 5.413429 5.470893
#> 6:     3 6.527107 censoring 0.3195034       3     4 5.470893 6.527107

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
#> L0      -0.31134   0.73246  0.19723 -1.579    0.114
#> relapse  0.47957   1.61537  0.08377  5.725 1.04e-08
#> 
#> Likelihood ratio test=33.55  on 2 df, p=5.174e-08
#> n= 804, number of events= 280 

# Splitting at t_prime tests whether an effect changes over time. Here L0
# raises the death hazard before time 2 only:
model_tv <- sim_model(
  L0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  death = sim_process("terminal", eta = 0.2, nu = 1),
  effects = list(sim_effect(death ~ L0 * (t < 2), coef = 1))
)
data_tv <- sim_events(model_tv, n = 2000)
data_split <- interval_format_data(data_tv, t_prime = 2)

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
#> L0:strata(t_group)t_group=1 0.91187   2.48898  0.06693 13.624 <2e-16
#> L0:strata(t_group)t_group=2 0.03978   1.04058  0.06651  0.598   0.55
#> 
#> Likelihood ratio test=200  on 2 df, p=< 2.2e-16
#> n= 2979, number of events= 2000 
```
