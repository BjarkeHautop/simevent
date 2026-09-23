# Build a Simulation Graph for `sim_event_graph()`

`sim_graph` assembles a set of named
[`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)/
[`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md)
nodes and
[`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)
edges between them into a single specification, which
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)
can then simulate from.

## Usage

``` r
sim_graph(..., effects = list())
```

## Arguments

- ...:

  Named
  [`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)/[`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md)
  objects. Every name must be unique across all three. A
  [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  covariate's dependencies must each name an earlier
  [`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  in the same call.

- effects:

  List of
  [`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)
  objects between nodes named in `...`.

## Value

An object of class `sim_graph`.

## See also

[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md),
[`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md),
[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md),
[`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md),
[`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)

## Examples

``` r
graph <- sim_graph(
  age = sim_covariate(function(N) rnorm(N)),
  age_sq = sim_derived(function(age) age^2),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.5),
    sim_effect("age_sq", "death", coef = -0.05)
  )
)
graph
#> <sim_graph>
#>   2 covariate(s): age, age_sq
#>   2 process(es): censoring, death
#>   2 effect(s)
```
