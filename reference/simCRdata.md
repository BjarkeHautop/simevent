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
#>        ID         Time Delta        L0    A0
#>     <int>        <num> <int>     <num> <num>
#>  1:     1 4.2505898708     1 0.5730568     0
#>  2:     2 1.2761060193     2 0.3918552     1
#>  3:     3 0.5794530904     0 0.9767038     0
#>  4:     4 1.3945334842     2 0.5483564     1
#>  5:     5 2.8643767672     1 0.3391972     1
#>  6:     6 3.0443682824     0 0.4441971     1
#>  7:     7 0.1212712415     0 0.9792817     0
#>  8:     8 1.9057723041     2 0.7248830     1
#>  9:     9 1.5560375853     1 0.9670641     1
#> 10:    10 0.0006683806     1 0.0302455     0
```
