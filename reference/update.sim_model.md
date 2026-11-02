# Update a `sim_model()`

Changes nodes and effects of an existing
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
and rebuilds it through
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
so all of its checks run again. Useful for sensitivity analyses and
scenario grids built from one base model; for fixing a covariate or
scaling a hazard in a single simulation, see
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)'s
`intervene` instead.

## Usage

``` r
# S3 method for class 'sim_model'
update(object, ..., effects = list(), drop_effects = list())
```

## Arguments

- object:

  A
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

- ...:

  Named
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)/[`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md)/[`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)/
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  objects. A name already in the model replaces that node in place; a
  new name is added after the existing nodes; `NULL` removes the node.

- effects:

  List of
  [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)s.
  One with the same formula as an existing effect replaces it; any other
  is added.

- drop_effects:

  Formula, or list of formulas, of effects to remove, e.g.
  `death ~ treated`. Effects using a removed node must be dropped here.

## Value

A
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`summary.sim_model()`](https://github.com/BjarkeHautop/simevent/reference/summary.sim_model.md)

## Examples

``` r
model <- sim_model(
  age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
  treated = sim_covariate(function(N) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect(death ~ age, coef = 0.03),
    sim_effect(death ~ treated, coef = -0.5)
  )
)

update(
  model,
  death = sim_process("terminal", eta = 0.1, nu = 1.5),
  frailty = sim_covariate(function(N) rgamma(N, shape = 2, rate = 2)),
  treated = NULL,
  effects = list(sim_effect(death ~ log(frailty), coef = 1)),
  drop_effects = death ~ treated
)
#> <sim_model>
#>   2 covariate(s): age, frailty
#>   2 process(es): censoring, death
#>   2 effect(s):
#>     death ~ 0.03 * age
#>     death ~ 1 * log(frailty)

# A grid of treatment effects:
models <- lapply(c(-1, -0.5, 0), function(b) {
  update(model, effects = list(sim_effect(death ~ treated, coef = b)))
})
```
