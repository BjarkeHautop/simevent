# Estimate Effect of Intervention: Modifying Eta Parameter of Process

This function simulates data from the disease setting in two scenarios.
Under intervention on the shape parameter \\\eta\\ of the disease
process is multiplied by `alpha`, and a baseline (non-intervened)
scenario. It computes the proportion of individuals who experience death
or disease by a specified time \\\tau\\ in the group `A0 = a0`,
optionally returning years_lost. The function can also plot a sample of
the event data for each scenario for comparison.

## Usage

``` r
intEffectAlpha(
  N = 10000,
  setting = "Disease",
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  alpha = 0.5,
  tau = 5,
  a0 = 1,
  years_lost = FALSE,
  plot = TRUE,
  lower = 10^(-30),
  upper = 200,
  cens = 0,
  ...
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate. Default is 10,000.

- setting:

  Character string. Must be either "Disease", "Drop In" or "Treatment".
  Depending on the simulation setting.

- eta:

  Numeric vector of length 3. Shape parameters for Weibull hazards
  (default `rep(0.1, 4)`).

- nu:

  Numeric vector of length 3. Scale parameters for Weibull hazards
  (default `rep(1.1, 4)`).

- alpha:

  Numeric scalar. Multiplicative factor applied to the disease process
  shape parameter \\\eta\\.

- tau:

  Numeric scalar. Time horizon at which proportions are computed.

- a0:

  Binary (0/1). Specifies the group for comparison.Only relevant in
  setting "Drop In" and "Disease".

- years_lost:

  Logical. If `TRUE`, computes years lost instead of proportions.

- plot:

  Logical. If `TRUE`, plots timelines for sample of intervention and non
  intervention data.

- lower:

  Numeric scalar. Lower bound for root-finding in hazard inversion
  (default 1e-30).

- upper:

  Numeric scalar. Upper bound for root-finding in hazard inversion
  (default 200).

- cens:

  Binary scalar. Indicates whether individuals are at risk of censoring
  (default `0`).

- ...:

  Additional arguments passed to respectively simDisease, simTreatment
  and simDropIn.

## Value

A list with two components:

- `effect_L`:

  Proportion (or years lost) of individuals diagnosed with disease by
  time \\\tau\\ in group `A0 = a0`, under intervention.

- `effect_death`:

  Proportion (or years lost) of individuals who died by time \\\tau\\ in
  group `A0 = a0`, under intervention.

## Examples

``` r
intEffectAlpha(N = 1000, alpha = 0.7, tau = 5, years_lost = FALSE, a0 = 1, setting = "Drop In")
#> Warning: Using `size` aesthetic for lines was deprecated in ggplot2 3.4.0.
#> ℹ Please use `linewidth` instead.
#> ℹ The deprecated feature was likely used in the simevent package.
#>   Please report the issue at <https://github.com/miclukacova/simevent/issues>.
#> $effect_2
#> [1] 0.527668
#> 
#> $effect_death
#> [1] 0.09486166
#> 
```
