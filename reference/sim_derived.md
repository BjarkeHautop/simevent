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
  effects = list(sim_effect("statin", "death", coef = -0.3))
)
head(sim_events(model, n = 5))
#> Key: <id>
#>       id       time  event   weight   height      bmi statin
#>    <int>      <num> <fctr>    <num>    <num>    <num>  <int>
#> 1:     1  8.8603295  death 76.12980 1.870273 21.76430      0
#> 2:     2  3.5636934  death 59.05287 1.638110 22.00669      0
#> 3:     3  0.8304477  death 91.27328 1.623237 34.64014      1
#> 4:     4 17.8972724  death 70.69576 1.757890 22.87758      0
#> 5:     5  2.9047275  death 84.71315 1.704788 29.14808      0
```
