# Simulation and Estimation with Modified Shape Parameter

This function simulates event history data from the Disease, Treatment,
Drop In, or Statin setting (see `simDisease`, `simTreatment`,
`simDropIn`, and `simStatinData`). The shape parameter \\\eta\\ of the
disease/treatment/drop-in/MACE process is multiplied by `alpha`. The
function either

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
  vector should match number of events: 3 for the Disease setting, 4 for
  the Drop In or Treatment setting, 12 for the Statin setting (default
  `rep(0.1, 4)`).

- nu:

  Numeric vector. Scale parameters for Weibull hazards. Length of the
  vector should match number of events: 3 for the Disease setting, 4 for
  the Drop In or Treatment setting, 12 for the Statin setting (default
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

  Character string. Must be "Disease", "Drop In", "Treatment", or
  "Statin". Depending on the simulation setting.

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

- `effectDeath`:

  Proportion (or years lost) of individuals who died by time \\\tau\\,
  under intervention.

- `effectSetting`:

  Proportion (or years lost) of individuals experiencing
  disease/drop-in/treatment/MACE by time \\\tau\\, under intervention.

Or the simulated data, if `return_data = TRUE`.

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
