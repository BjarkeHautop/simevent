# Define a Derived Covariate for `sim_model()`

`sim_derived` builds a covariate that is a deterministic transform of
one or more other covariates defined earlier in the same
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
call.

## Usage

``` r
sim_derived(fn)
```

## Arguments

- fn:

  Function of covariates defined earlier in the same
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  call, by name.

## Value

An object of class `sim_derived`, for use in
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md),
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)

## Examples

``` r
# BMI from weight (kg) and height (m), stored as its own column and usable
# by covariates defined after it:
model <- sim_model(
  weight = sim_covariate(function(N) rnorm(N, mean = 80, sd = 12)),
  height = sim_covariate(function(N) rnorm(N, mean = 1.75, sd = 0.08)),
  bmi = sim_derived(function(weight, height) weight / height^2),
  statin = sim_covariate(function(N, bmi) rbinom(N, 1, plogis(-5 + 0.15 * bmi))),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(sim_effect(death ~ statin, coef = -0.3))
)
head(sim_events(model, n = 5))
#> Key: <id>
#>       id        time  event   weight   height      bmi statin
#>    <int>       <num> <fctr>    <num>    <num>    <num>  <int>
#> 1:     1  4.88049827  death 98.74913 1.869041 28.26803      0
#> 2:     2  0.07393583  death 91.53571 1.747146 29.98694      0
#> 3:     3 39.87390394  death 89.13023 1.733519 29.65976      1
#> 4:     4  2.44170836  death 93.23339 1.615706 35.71469      0
#> 5:     5  1.75029058  death 83.93065 1.671902 30.02609      0
```
