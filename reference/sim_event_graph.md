# Simulate Event History Data from a `sim_graph()`

`sim_event_graph` simulates multistate event history data from a
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
specification, via the same underlying sampler as
[`simEventData()`](https://github.com/miclukacova/simevent/reference/simEventData.md).

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
  upper = 1e+08
)
```

## Arguments

- graph:

  A
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

- n:

  Integer. Number of individuals to simulate.

- intervene:

  Named list implementing a `do()`-style intervention on `graph`, for
  simulating counterfactual data without redefining the whole graph.
  Keyed by a covariate or process name from `graph`:

  Covariate name

  :   Overrides that
      [`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)/
      [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)'s
      draw, fixing it to the given constant for every individual instead
      of generating/deriving it.

  Process name

  :   Multiplies that process's baseline `eta`, scaling its hazard for
      everyone (e.g. `0.5` halves it, `2` doubles it).

- cens:

  Numeric. At-risk indicator scaling for `"censoring"`-type processes.
  Default 1.

- max_cens:

  Numeric. Maximum censoring time. Default `Inf`.

- max_events:

  Integer. Maximum number of events simulated per individual before an
  error is raised. Default 50.

- lower, upper:

  Numeric. Root-finding bounds for the inverse cumulative hazard, used
  only when processes don't all share the same Weibull shape/scale.
  Defaults `1e-25`/`1e8`.

## Value

A `data.table` with columns `id`, `time`, `delta` (the 0-indexed
position of the firing process in `graph`'s process order: censoring
processes first, then terminal, then the rest in declared order), the
graph's covariates, and one column per non-terminal, non-censoring
process (its cumulative event count).

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md),
[`simEventData()`](https://github.com/miclukacova/simevent/reference/simEventData.md),
[`sim.generic()`](https://github.com/miclukacova/simevent/reference/sim.generic.md)

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
#>       id     time delta      age treated illness checkup
#>    <int>    <num> <int>    <num>   <int>   <num>   <num>
#> 1:     1 1.292550     1 34.91989       1       0       0
#> 2:     2 1.027427     2 58.33178       1       1       0
#> 3:     2 1.151174     1 58.33178       1       1       0
#> 4:     3 1.602050     1 62.13573       0       0       0
#> 5:     4 1.124954     0 61.29368       1       0       0
#> 6:     5 1.141964     1 70.90688       1       0       0

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
#>       id      time delta      age treated illness checkup
#>    <int>     <num> <int>    <num>   <num>   <num>   <num>
#> 1:     1 1.0137010     0 58.86335       1       0       0
#> 2:     2 0.9827744     2 66.71151       1       1       0
#> 3:     2 1.4415732     3 66.71151       1       1       1
#> 4:     2 2.5331236     1 66.71151       1       1       1
#> 5:     3 1.4827995     1 50.03613       1       0       0
#> 6:     4 1.5151934     2 41.96813       1       1       0
```
