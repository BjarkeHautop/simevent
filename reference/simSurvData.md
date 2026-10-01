# Simulate Survival Data with Censoring and Event Times

`simSurvData()` is deprecated as of simevent 0.2.0. Use
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
instead.

## Usage

``` r
simSurvData(N, beta = NULL, eta = rep(0.1, 2), nu = rep(1.1, 2), cens = 1, ...)
```

## Arguments

- N:

  Numeric scalar. Number of individuals to simulate.

- beta:

  Numeric 2x2 matrix specifying effects of baseline covariates `L0` and
  `A0` on censoring and event hazards.

  - Rows correspond to covariates `L0` and `A0`.

  - Columns correspond to censoring (1st column) and event (2nd column).
    Defaults to zero matrix if `NULL`.

- eta:

  Numeric vector of length 2. Shape parameters for Weibull hazard with
  parameterization \\\eta \nu t^{\nu - 1}\\. Defaults to `rep(0.1, 2)`.

- nu:

  Numeric vector of length 2. Scale parameters for the Weibull hazard.
  Defaults to `rep(1.1, 2)`.

- cens:

  Numeric binary indicator (0 or 1) specifying if censoring is included
  (default 1).

- ...:

  Additional arguments passed to `simEventData`, including the argument
  `add_cov` to specify extra covariates.

## Value

A data frame containing the simulated survival data.

## Details

Simulates survival data for \\N\\ individuals who are at risk for
censoring (0) and an event (1). The hazard functions for censoring and
event times follow Weibull distributions parameterized by shape
parameters \\\eta\\ and scale parameters \\\nu\\. Covariate effects on
censoring and event hazards are specified via a matrix `beta`.

## Examples

``` r
simSurvData(10)
#> Warning: `simSurvData()` was deprecated in simevent 0.2.0.
#> ℹ Please use `sim_events()` instead.
#> Key: <ID>
#>        ID       Time Delta         L0    A0
#>     <int>      <num> <int>      <num> <num>
#>  1:     1  1.1127873     0 0.55928713     1
#>  2:     2 12.3736248     1 0.59689334     0
#>  3:     3  9.6191188     0 0.98844695     0
#>  4:     4  1.7185592     0 0.45875155     0
#>  5:     5  0.3525454     0 0.60826728     1
#>  6:     6  3.6778012     0 0.11794972     1
#>  7:     7  0.8459066     0 0.60990657     1
#>  8:     8  9.3370267     0 0.71560176     1
#>  9:     9  5.9411253     1 0.01457063     1
#> 10:    10  4.6452499     0 0.87532608     0
```
