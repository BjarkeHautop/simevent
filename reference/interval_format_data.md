# Transform Graph-Based Event Data into Interval Format for Classical Inference

Converts
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)
output into an interval (start-stop) format, suitable for classical
survival analysis functions like `coxph()`. Adds interval start and stop
times (`tstart`, `tstop`) and a counting variable `k` indexing events.
Optionally, the function can split intervals at a specified time point
to accommodate estimation of time-varying effects.

## Usage

``` r
interval_format_data(
  data,
  proc_cols = character(0),
  time_var = FALSE,
  t_prime = NULL
)
```

## Arguments

- data:

  A `data.table` as returned by
  [`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md):
  columns `id`, `time`, `delta`, baseline covariates, and one column per
  `"transient"` process.

- proc_cols:

  Character vector. Names of `data`'s `"transient"`-process columns
  (e.g. `names(graph$processes)` restricted to the transient ones),
  which get lagged by one row per `id` so each interval reports the
  process's cumulative count *before* that row's event. Default
  `character(0)` (no transient-process columns to lag).

- time_var:

  Logical. If `TRUE`, the intervals are split at `t_prime` to allow
  time-varying covariate effects. Default `FALSE`.

- t_prime:

  Numeric scalar. Time point at which to split intervals if
  `time_var = TRUE`.

## Value

A `data.table` with columns `tstart`, `tstop`, `k`, and the other
original columns, formatted for survival analysis.

## See also

[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)

## Examples

``` r
graph <- sim_graph(
  L0 = sim_covariate(function(N) runif(N)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1),
  effects = list(sim_effect("relapse", "death", 0.5))
)
data <- sim_event_graph(graph, n = 500)
data_int <- interval_format_data(data, proc_cols = "relapse")
head(data_int)
#>       id      time delta        L0 relapse     k   tstart     tstop
#>    <int>     <num> <int>     <num>   <num> <int>    <num>     <num>
#> 1:     1 1.6988933     0 0.3152944       0     1 0.000000 1.6988933
#> 2:     2 4.9282638     2 0.1121613       0     1 0.000000 4.9282638
#> 3:     2 6.3790613     0 0.1121613       1     2 4.928264 6.3790613
#> 4:     3 4.4633263     1 0.6211252       0     1 0.000000 4.4633263
#> 5:     4 0.1193703     1 0.6278351       0     1 0.000000 0.1193703
#> 6:     5 1.3924952     2 0.2475538       0     1 0.000000 1.3924952

# relapse is now the cumulative count *before* each row's event, so it can
# be used as a time-varying covariate:
survival::coxph(
  survival::Surv(tstart, tstop, delta == 1) ~ L0 + relapse,
  data = data_int
)
#> Call:
#> survival::coxph(formula = survival::Surv(tstart, tstop, delta == 
#>     1) ~ L0 + relapse, data = data_int)
#> 
#>             coef exp(coef) se(coef)      z        p
#> L0      -0.11642   0.89010  0.21433 -0.543    0.587
#> relapse  0.52509   1.69061  0.07353  7.141 9.23e-13
#> 
#> Likelihood ratio test=47.5  on 2 df, p=4.848e-11
#> n= 854, number of events= 272 
```
