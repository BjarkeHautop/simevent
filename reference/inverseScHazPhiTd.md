# Wrapper for inverse cumulative hazard with time-dependent phi

A wrapper around the Rcpp function `inverseScHazPhiTdCpp`, which
computes the inverse cumulative hazard using a closed-form expression
involving the incomplete gamma function.

## Usage

``` r
inverseScHazPhiTd(
  p,
  t,
  T_star,
  lower,
  upper,
  eta,
  nu,
  beta2,
  phi0,
  at_risk,
  tol = 1e-09,
  max_iter = 100
)
```

## Arguments

- p:

  Random variable to invert against the cumulative hazard (typically
  `-log(U)`).

- t:

  Current time.

- T_star:

  Numeric vector of most recent event times for each event type.

- lower:

  Lower bound for root finding.

- upper:

  Upper bound for root finding.

- eta:

  Numeric vector of Weibull scale parameters.

- nu:

  Numeric vector of Weibull shape parameters.

- beta2:

  Numeric vector controlling exponential decay/growth.

- phi0:

  Numeric vector of baseline multiplicative effects, typically
  `exp(L %*% beta1)`.

- at_risk:

  Numeric vector indicating whether each event type is at risk.

- tol:

  Numerical tolerance for root finding. Default is `1e-9`.

- max_iter:

  Maximum number of bisection iterations. Default is `100`.

## Value

A numeric scalar corresponding to the waiting time \\u\\.

## Details

The hazard for event type \\k\\ is assumed to be \$\$ \lambda_k(s) =
\eta_k \nu_k s^{\nu_k - 1} \phi\_{0k} \exp\left( -\beta\_{2k}(s -
T_k^\*) \right), \$\$

where \\T_k^\*\\ denotes the most recent event time.

## Examples

``` r
eta <- c(0.1, 0.2)
nu <- c(1.2, 1.5)
beta2 <- c(0.05, 0.1)
phi0 <- c(1, 1.5)
T_star <- c(0, 2)
at_risk <- c(1, 1)

inverseScHazPhiTd(
  p = 0.5,
  t = 3,
  T_star = T_star,
  lower = 1e-12,
  upper = 100,
  eta = eta,
  nu = nu,
  beta2 = beta2,
  phi0 = phi0,
  at_risk = at_risk
)
#> [1] 0.5907812
```
