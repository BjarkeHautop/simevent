# Simulate Event History Data from a `sim_graph()`

`sim_event_graph` simulates multistate event history data from a
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)
specification.

## Usage

``` r
sim_event_graph(
  graph,
  n,
  intervene = list(),
  cens = 1,
  max_cens = Inf,
  max_events = 50,
  lower = 1e-25,
  upper = 1e+08,
  time_step = 0.01,
  seed = NULL
)
```

## Arguments

- graph:

  A
  [`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md).

- n:

  Integer. Number of individuals to simulate.

- intervene:

  Named list of interventions. A covariate name fixes that covariate to
  the given value for everyone; a process name multiplies that process's
  hazard by the given value.

- cens:

  Numeric. Multiplier on censoring hazards; `0` turns censoring off.
  Default 1.

- max_cens:

  Numeric. End of follow-up: anyone still followed is censored then,
  with `event = "max_cens"`. Default `Inf`.

- max_events:

  Integer. Maximum number of events per individual. Default 50.

- lower, upper:

  Numeric. Root-finding bounds, used when processes have different
  Weibull parameters. Defaults `1e-25`/`1e8`.

- time_step:

  Numeric. Grid step on which
  [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)s
  using `t` are evaluated; ignored if none do. Smaller is more accurate
  but slower. Default `0.01`.

- seed:

  Integer. Random seed. Default `NULL` (no seed set).

## Value

A `data.table` with one row per event: `id`, `time`, `event` (factor
naming the process, or `"max_cens"`), the covariates, and each
`"transient"` process's number of events so far.

## See also

[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md),
[`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)

## Examples

``` r
# An illness-death graph: "age" is a plain covariate, "treated" is a
# second covariate whose generator depends on age, "illness" is a
# transient process capped at 2 events (limit = 2, e.g. two distinct
# relapse diagnoses) that can itself raise the death hazard, and "checkup"
# is an unlimited (limit = Inf) transient process.
graph <- sim_graph(
  age = sim_covariate(function(N) rnorm(N, mean = 50, sd = 10)),
  treated = sim_covariate(function(N, age) rbinom(N, 1, plogis(-2 + 0.03 * age))),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  illness = sim_process("transient", eta = 0.15, nu = 1.2, limit = 2),
  checkup = sim_process("transient", eta = 0.2, nu = 1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.03),
    sim_effect("treated", "death", coef = -0.5),
    sim_effect("illness", "death", coef = 1.2),
    sim_effect("checkup", "death", coef = 0.8)
  )
)
data <- sim_event_graph(graph, n = 100)
head(data)
#> Key: <id>
#>       id      time     event      age treated illness checkup
#>    <int>     <num>    <fctr>    <num>   <int>   <num>   <num>
#> 1:     1 0.7428918   illness 46.77483       0       1       0
#> 2:     1 0.9429819     death 46.77483       0       1       0
#> 3:     2 5.6927650   illness 32.54406       1       1       0
#> 4:     2 6.2212544     death 32.54406       1       1       0
#> 5:     3 1.2254362 censoring 59.39440       1       0       0
#> 6:     4 0.5906562     death 42.24647       0       0       0

# illness has fired at most twice for everyone (limit = 2):
all(data$illness <= 2)
#> [1] TRUE

# Double the censoring rate (cens scales every "censoring"-type process),
# halve the death hazard, and fix everyone's treatment status to 1:
data_intervened <- sim_event_graph(
  graph,
  n = 100,
  cens = 2,
  intervene = list(death = 0.5, treated = 1)
)
head(data_intervened)
#> Key: <id>
#>       id      time   event      age treated illness checkup
#>    <int>     <num>  <fctr>    <num>   <num>   <num>   <num>
#> 1:     1 0.7511419   death 55.77246       1       0       0
#> 2:     2 0.4602298 checkup 50.99660       1       0       1
#> 3:     2 2.0036459 checkup 50.99660       1       0       2
#> 4:     2 2.4155036 illness 50.99660       1       1       2
#> 5:     2 2.4245824   death 50.99660       1       1       2
#> 6:     3 2.7165851 checkup 39.97823       1       0       1
```
