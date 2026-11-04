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
head(simulate_events(model, n = 5))
#> Key: <id>
#>       id      time  event   weight   height      bmi statin
#>    <int>     <num> <fctr>    <num>    <num>    <num>  <int>
#> 1:     1  6.059204  death 63.82122 1.789165 19.93720      0
#> 2:     2  7.448265  death 92.97880 1.738392 30.76722      1
#> 3:     3 10.260390  death 76.24258 1.756277 24.71789      0
#> 4:     4  5.360454  death 67.50888 1.750508 22.03092      1
#> 5:     5  4.939471  death 96.12874 1.832260 28.63382      0
```
