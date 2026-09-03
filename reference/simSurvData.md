# Simulate Survival Data

Simulate Survival Data with Censoring and Event Times

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

Data frame containing the simulated survival data

## Details

Simulates survival data for \\N\\ individuals who are at risk for
censoring (0) and an event (1). The hazard functions for censoring and
event times follow Weibull distributions parameterized by shape
parameters \\\eta\\ and scale parameters \\\nu\\. Covariate effects on
censoring and event hazards are specified via a matrix `beta`.

## Examples

``` r
simSurvData(10)
#> Key: <ID>
#>        ID      Time Delta         L0    A0
#>     <int>     <num> <int>      <num> <num>
#>  1:     1 2.2648499     0 0.12745160     0
#>  2:     2 2.2107698     1 0.65611683     1
#>  3:     3 7.9994330     0 0.93855208     1
#>  4:     4 0.1460284     1 0.05214674     1
#>  5:     5 2.7266357     0 0.41839028     0
#>  6:     6 5.8732474     0 0.18845429     1
#>  7:     7 0.6810498     1 0.79408932     0
#>  8:     8 4.9997653     1 0.99244952     0
#>  9:     9 9.1992626     0 0.30924975     0
#> 10:    10 6.1177175     0 0.01837322     1
```
