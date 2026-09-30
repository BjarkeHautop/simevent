# Define an Event Process for `sim_graph()`

`sim_process` builds an event process whose baseline intensity is
Weibull, \$\$\lambda_0(t) = \eta \nu t^{\nu - 1},\$\$ i.e. cumulative
baseline hazard \\\eta t^\nu\\.
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)s
into the process multiply this baseline by \\\exp(\text{coef} \times
\text{from})\\.

## Usage

``` r
sim_process(
  type = c("censoring", "terminal", "transient"),
  eta,
  nu,
  limit = Inf
)
```

## Arguments

- type:

  One of:

  `"censoring"`

  :   Ends follow-up without an outcome event.

  `"terminal"`

  :   An outcome event ending follow-up (e.g. death).

  `"transient"`

  :   An event that doesn't end follow-up and can recur (e.g. relapse).

- eta:

  Numeric. Weibull scale parameter.

- nu:

  Numeric. Weibull shape parameter: `nu > 1` gives an increasing hazard,
  `nu < 1` a decreasing one, `nu = 1` a constant one.

- limit:

  Integer or `Inf`. Maximum number of events of a `"transient"` process.
  Default `Inf`.

## Value

An object of class `sim_process`, for use in
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md),
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)

## Examples

``` r
# Death, with a slowly increasing hazard:
sim_process("terminal", eta = 0.1, nu = 1.1)
#> $type
#> [1] "terminal"
#> 
#> $eta
#> [1] 0.1
#> 
#> $nu
#> [1] 1.1
#> 
#> $limit
#> [1] Inf
#> 
#> attr(,"class")
#> [1] "sim_process"

# A relapse process that can fire at most twice:
sim_process("transient", eta = 0.2, nu = 1, limit = 2)
#> $type
#> [1] "transient"
#> 
#> $eta
#> [1] 0.2
#> 
#> $nu
#> [1] 1
#> 
#> $limit
#> [1] 2
#> 
#> attr(,"class")
#> [1] "sim_process"
```
