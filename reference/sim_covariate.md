# Define a Baseline Covariate for `sim_model()`

Define a Baseline Covariate for
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

## Usage

``` r
sim_covariate(generator)
```

## Arguments

- generator:

  Function of `N` (number of individuals) returning the covariate's
  values. May also take covariates defined earlier in the same
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  call, by name.

## Value

An object of class `sim_covariate`, for use in
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)

## Examples

``` r
# A covariate that doesn't depend on any other:
sim_covariate(function(N) rnorm(N, mean = 50, sd = 10))
#> <sim_covariate> function (N) rnorm(N, mean = 50, sd = 10)

# A covariate whose generator depends on another covariate defined
# earlier in the same sim_model() call:
sim_covariate(function(N, age) rbinom(N, 1, plogis(-2 + 0.03 * age)))
#> <sim_covariate> function (N, age) rbinom(N, 1, plogis(-2 + 0.03 * age))
```
