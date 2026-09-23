# Define an Effect for `sim_graph()`

An effect is a directed, weighted edge from a baseline covariate or
process to a process's intensity: multiplying that process's baseline
hazard by `exp(coef)` while `from` is "active" (its drawn value for a
covariate, or its current event count for a process). For an effect that
isn't linear in an existing covariate (a categorical level, an
interaction, a threshold), define a
[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
covariate for it first and point `from` at that.

## Usage

``` r
sim_effect(from, to, coef)
```

## Arguments

- from:

  Character. Name of a covariate,
  [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  covariate, or process defined in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call.

- to:

  Character. Name of a process defined in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call.

- coef:

  Numeric. Cox-type coefficient.

## Value

An object of class `sim_effect`, for use in
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
