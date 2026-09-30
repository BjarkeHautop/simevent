# Summarise a `sim_graph()`

Tabulates a
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)'s
covariates, processes and effects.

## Usage

``` r
# S3 method for class 'sim_graph'
summary(object, ...)

# S3 method for class 'summary.sim_graph'
print(x, ...)
```

## Arguments

- object:

  A
  [`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md).

- ...:

  Not used.

- x:

  A `summary.sim_graph` object, as returned by
  [`summary()`](https://rdrr.io/r/base/summary.html).

## Value

A list of three `data.frame`s: `covariates`, `processes` and `effects`.

## See also

[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)

## Examples

``` r
graph <- sim_graph(
  age = sim_covariate(function(N) rnorm(N)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  relapse = sim_process("transient", eta = 0.2, nu = 1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("age", "death", coef = 0.5),
    sim_effect("relapse", "death", coef = 1)
  )
)
graph
#> <sim_graph>
#>   1 covariate(s): age
#>   3 process(es): censoring, relapse, death
#>   2 effect(s)
summary(graph)
#> <sim_graph> covariates
#>  name     kind
#>   age baseline
#> 
#> <sim_graph> processes
#>       name      type eta  nu limit
#>  censoring censoring 0.1 1.1   Inf
#>    relapse transient 0.2 1.0   Inf
#>      death  terminal 0.1 1.1   Inf
#> 
#> <sim_graph> effects
#>     from    to coef
#>      age death  0.5
#>  relapse death  1.0
```
