# Define a Baseline Covariate for `sim_graph()`

Define a Baseline Covariate for
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

## Usage

``` r
sim_covariate(generator)
```

## Arguments

- generator:

  Function generating the covariate. Takes `N` and, optionally, any
  subset of the names of other covariates defined earlier in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call, matched by argument name.

## Value

An object of class `sim_covariate`, for use in
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md),
[`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md)

## Examples

``` r
# A covariate that doesn't depend on any other:
sim_covariate(function(N) rnorm(N, mean = 50, sd = 10))
#> $generator
#> function (N) 
#> rnorm(N, mean = 50, sd = 10)
#> <environment: 0x55f9a9729e10>
#> 
#> attr(,"class")
#> [1] "sim_covariate"

# A covariate whose generator depends on another covariate defined
# earlier in the same sim_graph() call:
sim_covariate(function(N, age) rbinom(N, 1, plogis(-2 + 0.03 * age)))
#> $generator
#> function (N, age) 
#> rbinom(N, 1, plogis(-2 + 0.03 * age))
#> <environment: 0x55f9a9729e10>
#> 
#> attr(,"class")
#> [1] "sim_covariate"
```
