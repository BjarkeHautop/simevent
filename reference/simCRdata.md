# Simulate Competing Risks Data

Simulates competing risks data for \\N\\ individuals who are at risk of
mutually exclusive event types. Three event types are simulated, where
one can be interpreted as censoring.

## Usage

``` r
simCRdata(N, beta = NULL, eta = rep(0.1, 3), nu = rep(1.1, 3), cens = 1, ...)
```

## Arguments

- N:

  Integer. Number of individuals to simulate.

- beta:

  Numeric matrix of dimension 2x3. Covariate effects of `L0` and `A0` on
  the three competing processes (columns correspond to processes).
  Defaults to zero matrix if `NULL`.

- eta:

  Numeric vector of length 3. Shape parameters for Weibull hazards,
  parameterized as \\\eta \nu t^{\nu - 1}\\. Defaults to `rep(0.1, 3)`.

- nu:

  Numeric vector of length 3. Scale parameters for Weibull hazards.
  Defaults to `rep(1.1, 3)`.

- cens:

  Binary (0 or 1). Indicates if a censoring process is included. Default
  is 1.

- ...:

  Additional arguments passed to
  [`simEventData`](https://github.com/miclukacova/simevent/reference/simEventData.md),
  including `add_cov` for extra covariates.

## Value

A `data.frame` with simulated competing risk data including:

- `ID` - Individual identifier.

- `Time` - Event time.

- `Delta` - Event type (0, 1, or 2).

- `L0` - Baseline covariate.

- `A0` - Baseline treatment indicator.

## Details

The event intensities follow Weibull hazard models parameterized by
shape and scale parameters \\\eta\\ and \\\nu\\. Covariate effects on
the hazard are specified by the `beta` matrix, which models the effects
of baseline covariates `L0` and `A0` on each event type.

## Examples

``` r
simCRdata(10)
#> Key: <ID>
#>        ID      Time Delta         L0    A0
#>     <int>     <num> <int>      <num> <num>
#>  1:     1 0.8194705     1 0.35034257     0
#>  2:     2 1.8516074     0 0.63519599     1
#>  3:     3 2.3006989     1 0.19395692     1
#>  4:     4 5.3695236     0 0.66341650     0
#>  5:     5 1.0707604     0 0.01061891     0
#>  6:     6 0.3311265     1 0.62805702     0
#>  7:     7 4.5119955     1 0.19838308     1
#>  8:     8 1.7009715     1 0.16762949     0
#>  9:     9 2.6145047     2 0.95716696     1
#> 10:    10 3.2229913     1 0.68390902     0
```
