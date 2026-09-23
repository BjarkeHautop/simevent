# Define a Derived Covariate for `sim_graph()`

`sim_derived` builds a covariate that is a deterministic transform of
one or more other covariates defined earlier in the same
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
call.

## Usage

``` r
sim_derived(fn)
```

## Arguments

- fn:

  Function of one or more covariates defined earlier in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call, matched by argument name.

## Value

An object of class `sim_derived`, for use in
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md),
[`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md),
[`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)

## Examples

``` r
# A categorical covariate's per-level dummy:
sim_derived(function(region) as.numeric(region == 2))
#> $fn
#> function (region) 
#> as.numeric(region == 2)
#> <environment: 0x55f99e44ecc0>
#> 
#> attr(,"class")
#> [1] "sim_derived"

# An interaction between two covariates:
sim_derived(function(L0, A0) L0 * A0)
#> $fn
#> function (L0, A0) 
#> L0 * A0
#> <environment: 0x55f99e44ecc0>
#> 
#> attr(,"class")
#> [1] "sim_derived"
```
