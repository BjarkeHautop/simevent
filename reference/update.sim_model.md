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
update(object, ..., effects = list(), drop_effects = character(0))
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
  One with the same `from` and `to` as an existing effect replaces it;
  any other is added.

- drop_effects:

  Character vector of effects to remove, as `"<from> -> <to>"` (as
  listed by
  [`summary.sim_model()`](https://github.com/BjarkeHautop/simevent/reference/summary.sim_model.md)).
  Effects using a removed node must be dropped here.

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
    sim_effect("age", "death", coef = 0.03),
    sim_effect("treated", "death", coef = -0.5)
  )
)

update(
  model,
  death = sim_process("terminal", eta = 0.1, nu = 1.5),
  frailty = sim_covariate(function(N) rgamma(N, shape = 2, rate = 2)),
  treated = NULL,
  effects = list(sim_effect("log(frailty)", "death", coef = 1)),
  drop_effects = "treated -> death"
)
#> <sim_model>
#>   2 covariate(s): age, frailty
#>   2 process(es): censoring, death
#>   2 effect(s)

# A grid of treatment effects:
models <- lapply(c(-1, -0.5, 0), function(b) {
  update(model, effects = list(sim_effect("treated", "death", coef = b)))
})
```
