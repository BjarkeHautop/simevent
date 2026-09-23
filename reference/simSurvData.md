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
#>        ID      Time Delta          L0    A0
#>     <int>     <num> <int>       <num> <num>
#>  1:     1  7.986616     0 0.460997913     1
#>  2:     2  7.398976     0 0.604622570     1
#>  3:     3 10.505991     0 0.009191813     0
#>  4:     4  3.950963     1 0.202736926     1
#>  5:     5  4.853135     0 0.162263735     0
#>  6:     6  4.091087     0 0.551314138     1
#>  7:     7  3.768537     0 0.073273248     1
#>  8:     8  5.389963     1 0.875944501     0
#>  9:     9  7.097592     1 0.765253324     1
#> 10:    10  9.828971     0 0.680900069     1
```
