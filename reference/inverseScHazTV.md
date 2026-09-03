# Wrapper for inverse cumulative hazard

A wrapper around the Rcpp function `inverseScHazCppTV`, used to find the
inverse of the summed cumulative hazard.

## Usage

``` r
inverseScHazTV(
  p,
  t,
  lower = 1e-15,
  upper = 200,
  t_prime,
  eta,
  nu,
  phi,
  phi_prime,
  at_risk,
  tol = 1e-09,
  max_iter = 100
)
```

## Arguments

- p:

  The random variable (typically `-log(U)`).

- t:

  The time of the previous event

- lower:

  Lower bound for root finding.

- upper:

  Upper bound for root finding.

- t_prime:

  The time where the time varying effects change

- eta:

  Numeric vector of shape parameters.

- nu:

  Numeric vector of scale parameters.

- phi:

  Numeric vector of multiplicative effect bedfore time t_prime

- phi_prime:

  Numeric vector of multiplicative effects after time t_prime

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
phi_prime <- c(2, 2)
inverseScHazTV(p = 0.5, t= 1, t_prime = 2, eta = eta, nu = nu,
                       phi = phi, phi_prime = phi_prime, at_risk = at_risk)
#> [1] 1.567826
```
