# Estimate Effect of Intervention: Modifying Eta Parameter of Process

Simulates data from the Disease, Drop In, or Treatment setting under an
intervention where the shape parameter \\\eta\\ of the disease, drop-in,
or treatment process (respectively) is multiplied by `alpha`. It
computes the proportion of individuals who experience death, and the
proportion who experience disease/drop-in/treatment, by a specified time
\\\tau\\ in the group `A0 = a0` (except in the Treatment setting, where
all individuals are used), optionally returning years lost instead of
proportions. The function can also plot a sample of the simulated
(intervened) event data.

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

  Numeric vector. Shape parameters for Weibull hazards: length 3 for
  setting "Disease", length 4 for "Drop In" or "Treatment" (default
  `rep(0.1, 4)`).

- nu:

  Numeric vector. Scale parameters for Weibull hazards: length 3 for
  setting "Disease", length 4 for "Drop In" or "Treatment" (default
  `rep(1.1, 4)`).

- alpha:

  Numeric scalar. Multiplicative factor applied to the shape parameter
  \\\eta\\ of the relevant process.

- tau:

  Numeric scalar. Time horizon at which proportions are computed.

- a0:

  Binary (0/1). Specifies the group for comparison. Only relevant in
  setting "Drop In" and "Disease".

- years_lost:

  Logical. If `TRUE`, computes years lost instead of proportions.

- plot:

  Logical. If `TRUE`, plots a sample of the simulated event data.

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

- `effect_2`:

  Proportion (or years lost) of individuals experiencing
  disease/drop-in/treatment by time \\\tau\\, under intervention.

- `effect_death`:

  Proportion (or years lost) of individuals who died by time \\\tau\\,
  under intervention.

## Examples

``` r
intEffectAlpha(N = 1000, alpha = 0.7, tau = 5, years_lost = FALSE, a0 = 1, setting = "Drop In")
#> $effect_2
#> [1] 0.527668
#> 
#> $effect_death
#> [1] 0.09486166
#> 
```
