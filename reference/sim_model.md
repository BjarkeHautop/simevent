# Build a Simulation Model for `sim_events()`

`sim_model` assembles a set of named
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md)/
[`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
nodes and
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)
edges between them into a single specification, which
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
can then simulate from.

## Usage

``` r
sim_model(..., effects = list())
```

## Arguments

- ...:

  Named
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md)/[`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  objects. A covariate may only depend on covariates listed before it.

- effects:

  List of
  [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)s.

## Value

An object of class `sim_model`.

## See also

[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md),
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md),
[`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md),
[`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md),
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)

## Examples

``` r
model <- sim_model(
  age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.03),
    sim_effect("(age - 60)^2", "death", coef = 0.001)
  )
)
model
#> <sim_model>
#>   1 covariate(s): age
#>   2 process(es): censoring, death
#>   2 effect(s)
```
