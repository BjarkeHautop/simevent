# Summarise a `sim_model()`

Tabulates a
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)'s
covariates, processes and effects.

## Usage

``` r
# S3 method for class 'sim_model'
summary(object, ...)

# S3 method for class 'summary.sim_model'
print(x, ...)
```

## Arguments

- object:

  A
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

- ...:

  Not used.

- x:

  A `summary.sim_model` object, as returned by
  [`summary()`](https://rdrr.io/r/base/summary.html).

## Value

A list of three `data.frame`s: `covariates`, `processes` and `effects`.

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

## Examples

``` r
model <- sim_model(
  age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.03),
    sim_effect("relapse", "death", coef = 1)
  )
)
model
#> <sim_model>
#>   1 covariate(s): age
#>   3 process(es): censoring, relapse, death
#>   2 effect(s)
summary(model)
#> <sim_model> covariates
#>  name     kind
#>   age baseline
#> 
#> <sim_model> processes
#>       name      type baseline eta  nu limit
#>  censoring censoring  weibull 0.1 1.1   Inf
#>    relapse transient  weibull 0.2 1.0   Inf
#>      death  terminal  weibull 0.1 1.1   Inf
#> 
#> <sim_model> effects
#>     from    to coef
#>      age death 0.03
#>  relapse death 1.00
```
