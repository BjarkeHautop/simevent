# Simulate Event History Data from a `sim_model()`

`sim_events` simulates multistate event history data from a
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
specification.

## Usage

``` r
sim_events(
  model,
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

- model:

  A
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

- n:

  Integer. Number of individuals to simulate.

- intervene:

  Named list of interventions. A covariate or mark name fixes it to the
  given value for everyone, for all time; a process name multiplies that
  process's hazard by the given value.

- cens:

  Numeric. Multiplier on censoring hazards; `0` turns censoring off.
  Default 1.

- max_cens:

  Numeric. End of follow-up: anyone still followed is censored then,
  with `event = "max_cens"`. Default `Inf`. Follow-up also ends at the
  last `time` of any
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  `cumhaz` curve.

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
naming the process, or `"max_cens"`), the covariates (each
[`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)
followed by its baseline value, as `<name>_0`), and each `"transient"`
process's number of events so far.

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)

## Examples

``` r
# An illness-death model: "age" is a plain covariate, "treated" is a
# second covariate whose generator depends on age, "illness" is a
# transient process capped at 2 events (limit = 2, e.g. two distinct
# relapse diagnoses) that can itself raise the death hazard, and "checkup"
# is an unlimited (limit = Inf) transient process.
model <- sim_model(
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
data <- sim_events(model, n = 100)
head(data)
#> Key: <id>
#>       id      time     event      age treated illness checkup
#>    <int>     <num>    <fctr>    <num>   <int>   <num>   <num>
#> 1:     1 3.8110136 censoring 42.04579       1       0       0
#> 2:     2 0.1110879     death 57.96752       0       0       0
#> 3:     3 0.1180907     death 45.74632       0       0       0
#> 4:     4 1.1178542   checkup 41.32583       1       0       1
#> 5:     4 1.7589550     death 41.32583       1       0       1
#> 6:     5 0.9706924     death 49.84438       1       0       0

# illness has fired at most twice for everyone (limit = 2):
all(data$illness <= 2)
#> [1] TRUE

# Double the censoring rate (cens scales every "censoring"-type process),
# halve the death hazard, and fix everyone's treatment status to 1:
data_intervened <- sim_events(
  model,
  n = 100,
  cens = 2,
  intervene = list(death = 0.5, treated = 1)
)
head(data_intervened)
#> Key: <id>
#>       id      time     event      age treated illness checkup
#>    <int>     <num>    <fctr>    <num>   <num>   <num>   <num>
#> 1:     1 0.2028894   illness 57.30123       1       1       0
#> 2:     1 1.4002603   checkup 57.30123       1       1       1
#> 3:     1 1.8264726     death 57.30123       1       1       1
#> 4:     2 0.1005794   illness 71.22464       1       1       0
#> 5:     2 0.2775342 censoring 71.22464       1       1       0
#> 6:     3 0.9454283 censoring 41.52353       1       0       0
```
