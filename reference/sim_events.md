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
  given single value for everyone, for all time; a process name
  multiplies that process's hazard by the given non-negative number.

- cens:

  Non-negative numeric. Multiplier on censoring hazards; `0` turns
  censoring off. Default 1.

- max_cens:

  Positive numeric. End of follow-up: anyone still followed is censored
  then, with `event = "max_cens"`. Default `Inf`. Follow-up also ends at
  the last `time` of any
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  `cumhaz` curve.

- max_events:

  Integer. Maximum number of events per individual. Default 50.

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
    sim_effect(death ~ age, coef = 0.03),
    sim_effect(death ~ treated, coef = -0.5),
    sim_effect(death ~ illness, coef = 1.2),
    sim_effect(death ~ checkup, coef = 0.8)
  )
)
data <- sim_events(model, n = 100)
head(data)
#> Key: <id>
#>       id       time     event      age treated illness checkup
#>    <int>      <num>    <fctr>    <num>   <int>   <num>   <num>
#> 1:     1 0.20700885   checkup 47.04180       1       0       1
#> 2:     1 1.34353737 censoring 47.04180       1       0       1
#> 3:     2 0.08574478     death 68.11898       0       0       0
#> 4:     3 1.24193098     death 46.90377       0       0       0
#> 5:     4 0.65822754   checkup 41.62570       0       0       1
#> 6:     4 1.82935437     death 41.62570       0       0       1

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
#> 1:     1 0.5038067   checkup 57.69649       1       0       1
#> 2:     1 2.8395612   illness 57.69649       1       1       1
#> 3:     1 3.4014899 censoring 57.69649       1       1       1
#> 4:     2 0.2444779   illness 73.56723       1       1       0
#> 5:     2 0.5264845     death 73.56723       1       1       0
#> 6:     3 0.1552247 censoring 57.89833       1       0       0
```
