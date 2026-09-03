# Wrapper for inverse cumulative hazard

A wrapper around the Rcpp function `inverseScHaz`, used to find the
inverse by numeric methods in case of no simple analytical solution.

## Usage

``` r
inverseScHaz(
  p,
  t,
  lower,
  upper,
  eta,
  nu,
  phi,
  at_risk,
  tol = 1e-09,
  max_iter = 100
)
```

## Arguments

- p:

  The random variable (typically `-log(U)`).

- t:

  Current time.

- lower:

  Lower bound for root finding.

- upper:

  Upper bound for root finding.

- eta:

  Numeric vector of shape parameters.

- nu:

  Numeric vector of scale parameters.

- phi:

  Numeric vector of multiplicative effects.

- at_risk:

  Numeric vector indicating at-risk indicators for each event type.

- tol:

  Numeric tolerance for root-finding. Default is 1e-9.

- max_iter:

  Maximum iterations. Default is 100.

## Value

A numeric scalar, the root `u`.

## Examples

``` r
eta <- c(0.1, 0.1)
nu <- c(1.1, 1.1)
phi <- c(1, 1)
at_risk <- c(1, 1)
inverseScHaz(0.5, t = 0, lower = 1e-15, upper = 200, eta, nu, phi, at_risk)
#> [1] 2.30019
```
