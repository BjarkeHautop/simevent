# Risk of, or Time Lost to, an Event by a Time Horizon

With \\T\\ the time of an individual's first `process` event (\\\infty\\
if none):

- `"risk"`:

  \\P(T \le \tau)\\.

- `"time_lost"`:

  \\E\[\tau - \min(T, \tau)\]\\, the restricted mean time lost.

Compare runs with and without
[`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)'s
`intervene` to estimate an intervention's effect. Estimates are biased
if anyone is censored before `tau` (a warning is given); simulate with
`cens = 0` to avoid this.

## Usage

``` r
event_risk(
  data,
  model,
  process,
  tau,
  type = c("risk", "time_lost"),
  by = character(0)
)
```

## Arguments

- data:

  Output of
  [`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md).

- model:

  The
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  `data` was simulated from.

- process:

  Character vector. Process(es) to summarise.

- tau:

  Numeric. Time horizon.

- type:

  `"risk"` (default) or `"time_lost"`.

- by:

  Character vector. Baseline columns of `data` to summarise within. A
  [`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)
  changes over follow-up, so group by its baseline value `<mark>_0`
  instead; transient process counts can't be used.

## Value

A `data.table` with the `by` columns, `process`, and the estimate
(column named after `type`).

## See also

[`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)

## Examples

``` r
model <- sim_model(
  A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  disease = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  effects = list(
    sim_effect(death ~ A0, coef = 0.5),
    sim_effect(death ~ disease, coef = 1)
  )
)

# Halve the disease hazard and compare against no intervention:
set.seed(1)
observed <- simulate_events(model, n = 2000)
intervened <- simulate_events(
  model,
  n = 2000,
  intervene = list(disease = 0.5)
)

event_risk(observed, model, c("death", "disease"), tau = 5)
#>    process   risk
#>     <char>  <num>
#> 1:   death 0.6150
#> 2: disease 0.3345
event_risk(intervened, model, c("death", "disease"), tau = 5)
#>    process  risk
#>     <char> <num>
#> 1:   death 0.572
#> 2: disease 0.177

# Years lost before tau, separately for A0 = 0 and A0 = 1:
event_risk(intervened, model, "death", tau = 5, type = "time_lost", by = "A0")
#>       A0 process time_lost
#>    <int>  <char>     <num>
#> 1:     0   death  1.286546
#> 2:     1   death  1.821648

# Group by a sim_mark()'s baseline value, <mark>_0 (the mark itself changes
# over follow-up, so by = "L" is an error):
draw_l <- function(N) rbinom(N, 1, 0.5)
model_l <- sim_model(
  L = sim_mark(draw_l, "visit", draw_l),
  visit = sim_process("transient", eta = 0.5, nu = 1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(sim_effect(death ~ L, coef = 1))
)
data_l <- simulate_events(model_l, n = 2000)
event_risk(data_l, model_l, "death", tau = 5, by = "L_0")
#>      L_0 process      risk
#>    <int>  <char>     <num>
#> 1:     0   death 0.5836576
#> 2:     1   death 0.7170782
```
