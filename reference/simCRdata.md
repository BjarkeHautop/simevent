# Simulate Competing Risks Data

`simCRdata()` is deprecated as of simevent 0.2.0. Use
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
instead.

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
  [`simEventData`](https://github.com/BjarkeHautop/simevent/reference/simEventData.md),
  including `add_cov` for extra covariates.

## Value

A `data.frame` with simulated competing risk data including:

- `ID` - Individual identifier.

- `Time` - Event time.

- `Delta` - Event type (0, 1, or 2).

- `L0` - Baseline covariate.

- `A0` - Baseline treatment indicator.

## Details

Simulates competing risks data for \\N\\ individuals who are at risk of
mutually exclusive event types. Three event types are simulated, where
one can be interpreted as censoring.

The event intensities follow Weibull hazard models parameterized by
shape and scale parameters \\\eta\\ and \\\nu\\. Covariate effects on
the hazard are specified by the `beta` matrix, which models the effects
of baseline covariates `L0` and `A0` on each event type.

## Examples

``` r
simCRdata(10)
#> Warning: `simCRdata()` was deprecated in simevent 0.2.0.
#> ℹ Please use `sim_events()` instead.
#> Key: <ID>
#>        ID      Time Delta        L0    A0
#>     <int>     <num> <int>     <num> <num>
#>  1:     1 6.0442668     0 0.3162765     0
#>  2:     2 4.4386148     1 0.3821263     0
#>  3:     3 1.1367909     0 0.2157253     1
#>  4:     4 5.5481918     0 0.2025056     1
#>  5:     5 1.5611560     0 0.8611681     0
#>  6:     6 9.9367915     0 0.7248675     0
#>  7:     7 0.7154495     2 0.7474930     0
#>  8:     8 1.5399186     2 0.3956398     0
#>  9:     9 4.7857215     2 0.9002984     1
#> 10:    10 4.4892693     1 0.2064856     0
```
