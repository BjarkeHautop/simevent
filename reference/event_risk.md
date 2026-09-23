# Risk of, or Time Lost to, an Event by a Time Horizon

`event_risk` summarises
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)
output by the proportion of individuals who have experienced a process
by time `tau` (the absolute risk / cumulative incidence), or by the
expected time lost to it before `tau`. Combined with
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)'s
`intervene` argument, this is how to estimate the effect of an
intervention: simulate once with and once without the intervention, and
compare the two summaries.

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

  A `data.table` as returned by
  [`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md).

- graph:

  The
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  `data` was simulated from, used to map process names to `data`'s
  `delta` codes.

- process:

  Character vector. Name(s) of processes in `graph` to summarise, each
  separately.

- tau:

  Numeric scalar. Time horizon.

- type:

  Either `"risk"` (default) or `"time_lost"`.

- by:

  Character vector. Names of `data` columns (typically baseline
  covariates) to summarise within levels of. Default `character(0)` (all
  individuals together).

## Value

A `data.table` with the `by` columns, `process`, and a column named
after `type` holding the estimate.

## Details

For each individual, only the *first* event of `process` counts
(relevant for a `"transient"` process that can fire more than once).
With \\T\\ that first event time (infinite if it never occurs):

- `"risk"`:

  \\P(T \le \tau)\\.

- `"time_lost"`:

  \\E\[\tau - \min(T, \tau)\]\\, the restricted mean time lost, i.e. the
  area under the risk curve on \\\[0, \tau\]\\.

Both are plain empirical averages over individuals, which are only
unbiased when no one is censored before `tau`. Simulate with `cens = 0`
(or a graph without a `"censoring"` process) to get the uncensored
counterfactual; a warning is given otherwise.

## See also

[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)

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
