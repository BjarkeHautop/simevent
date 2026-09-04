# Simulate Survival Data with Censoring and Event Times

Simulates survival data for \\N\\ individuals who are at risk for
censoring (0) and an event (1). The hazard functions for censoring and
event times follow Weibull distributions parameterized by shape
parameters \\\eta\\ and scale parameters \\\nu\\. Covariate effects on
censoring and event hazards are specified via a matrix `beta`.

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

## Examples

``` r
simSurvData(10)
#> Key: <ID>
#>        ID       Time Delta        L0    A0
#>     <int>      <num> <int>     <num> <num>
#>  1:     1  3.7499427     0 0.5244502     1
#>  2:     2  1.9588293     0 0.9606196     1
#>  3:     3  0.6504944     1 0.4502577     1
#>  4:     4  0.2382066     0 0.6904295     1
#>  5:     5  2.0249737     0 0.5558746     0
#>  6:     6  0.5203266     1 0.7301653     0
#>  7:     7  3.7719245     1 0.2766879     1
#>  8:     8  2.2253061     0 0.6055574     1
#>  9:     9 10.5564508     1 0.9555500     0
#> 10:    10  3.1751765     0 0.9398369     0
```
