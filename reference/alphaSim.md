# Simulation and Estimation with Modified Shape Parameter

This function simulates event history data from either the Disease,
Treatment or Drop In setting. See simDisease, simTreatment and
simDropIn. The shape parameter \\\eta\\ of respectively the disease
process, the Drop In process and the Treatment process is multiplied by
`alpha`. The function either

- returns the proportion of individuals who experience death and the
  proportion of individuals who experience disease/drop in/treatment by
  a specified time \\\tau\\ (in group `A0 = a0` for drop in and
  disease).

- returns number of years lost before \\\tau\\ of death and disease/drop
  in/treatment

- returns simulated data. One can specify all the same parameters as in
  the functions `simDisease`, `simTreatment` and `simDropIn`.

## Usage

``` r
alphaSim(
  N = 10000,
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  alpha = 0.5,
  tau = 5,
  a0 = 1,
  years_lost = FALSE,
  setting = "Disease",
  return_data = FALSE,
  cens = 0,
  ...
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate. Default is 10,000.

- eta:

  Numeric vector. Shape parameters for Weibull hazards. Length of the
  vector should match number of events. For the Disease and Drop In
  setting this is 4. For the Treatment setting, this is 3. (default
  `rep(0.1, 4)`).

- nu:

  Numeric vector. Scale parameters for Weibull hazards. Length of the
  vector should match number of events. For the Disease and Drop In
  setting this is 4. For the Treatment setting, this is 3. (default
  `rep(1.1, 4)`).

- alpha:

  Numeric scalar. Multiplicative factor applied to the disease process
  shape parameter \\\eta\\.

- tau:

  Numeric scalar. Time horizon at which proportions are computed.

- a0:

  Binary (0/1). Specifies the group for comparison in setting Drop In
  and Disease.

- years_lost:

  Logical. If `TRUE`, computes years lost instead of proportions.

- setting:

  Character string. Must be either "Disease", "Drop In" or "Treatment".
  Depending on the simulation setting.

- return_data:

  Logical. If `TRUE` the simulated data is returned.

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
  time \\\tau\\, under intervention.

- `effect_death`:

  Proportion (or years lost) of individuals who died by time \\\tau\\
  under intervention.

Or the simulated data.

## Examples

``` r
alphaSim(N = 100, eta = rep(0.1,3), nu = rep(1.1,3), alpha = 0.5, setting = "Disease")
#> $effectDeath
#> [1] 0.6607143
#> 
#> $effectSetting
#> [1] 0.3035714
#> 
alphaSim(N = 100, setting = "Drop In", beta_A0_Z = 1)
#> $effectDeath
#> [1] 0.06122449
#> 
#> $effectSetting
#> [1] 0.6734694
#> 
```
