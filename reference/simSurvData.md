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
#>  1:     1 3.8161597     1 0.646411285     0
#>  2:     2 9.7445728     1 0.548612530     1
#>  3:     3 6.7730454     0 0.381062445     1
#>  4:     4 4.6586870     0 0.463444044     0
#>  5:     5 5.9127216     1 0.002773173     1
#>  6:     6 3.4665695     0 0.232408226     1
#>  7:     7 1.3453667     1 0.396454289     0
#>  8:     8 0.2687670     1 0.825148441     0
#>  9:     9 0.1539439     1 0.396773600     0
#> 10:    10 2.0148975     1 0.354466980     0
```
