# Risk of, or Time Lost to, an Event by a Time Horizon

With \\T\\ the time of an individual's first `process` event (\\\infty\\
if none):

- `"risk"`:

  \\P(T \le \tau)\\.

- `"time_lost"`:

  \\E\[\tau - \min(T, \tau)\]\\, the restricted mean time lost.

Compare runs with and without
[`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md)'s
`intervene` to estimate an intervention's effect. Estimates are biased
if anyone is censored before `tau` (a warning is given); simulate with
`cens = 0` to avoid this.

## Usage

``` r
event_risk(
  data,
  graph,
  process,
  tau,
  type = c("risk", "time_lost"),
  by = character(0)
)
```

## Arguments

- data:

  Output of
  [`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md).

- graph:

  The
  [`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)
  `data` was simulated from.

- process:

  Character vector. Process(es) to summarise.

- tau:

  Numeric. Time horizon.

- type:

  `"risk"` (default) or `"time_lost"`.

- by:

  Character vector. Columns of `data` to summarise within.

## Value

A `data.table` with the `by` columns, `process`, and the estimate
(column named after `type`).

## See also

[`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md)

## Examples

``` r
graph <- sim_graph(
  A0 = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  disease = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  effects = list(
    sim_effect("A0", "death", coef = 0.5),
    sim_effect("disease", "death", coef = 1)
  )
)

# Halve the disease hazard and compare against no intervention:
set.seed(1)
observed <- sim_event_graph(graph, n = 2000)
intervened <- sim_event_graph(graph, n = 2000, intervene = list(disease = 0.5))

event_risk(observed, graph, c("death", "disease"), tau = 5)
#>    process   risk
#>     <char>  <num>
#> 1:   death 0.6150
#> 2: disease 0.3345
event_risk(intervened, graph, c("death", "disease"), tau = 5)
#>    process  risk
#>     <char> <num>
#> 1:   death 0.572
#> 2: disease 0.177

# Years lost before tau, separately for A0 = 0 and A0 = 1:
event_risk(intervened, graph, "death", tau = 5, type = "time_lost", by = "A0")
#>       A0 process time_lost
#>    <int>  <char>     <num>
#> 1:     0   death  1.286546
#> 2:     1   death  1.821648
```
