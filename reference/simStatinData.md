# Simulate Data in a Statin Setting

Simulate Data in a Statin Setting

## Usage

``` r
simStatinData(
  N,
  eta = NULL,
  nu = NULL,
  beta = NULL,
  followup = 5,
  lower = 10^(-15),
  upper = 200,
  gen_A0 = function(N, L0) pmin(stats::rexp(N, 0.3) + 70, 100),
  gen_L0 = function(N) stats::rbinom(N, 1, 0.4),
  add_cov = NULL,
  at_risk = NULL,
  ...
)
```

## Arguments

- N:

  Numeric scalar. Number of individuals to simulate.

- eta:

  Numeric vector of length equal to number of processes. Shape
  parameters for Weibull intensities with parameterization \\\eta \nu
  t^{\nu - 1}\\. Defaults to `rep(0.1, 8)`.

- nu:

  Numeric vector of length equal to number of processes. Scale
  parameters for the Weibull hazards. Defaults to `rep(1.1, 8)`.

- beta:

  Numeric matrix. Of dimension p times 6. Regression coefficients matrix
  where columns correspond to event types (N0, ..., N5) and rows
  correspond to covariates (L0, A0, L1, L2, ...) followed by event
  counts (N0, ..., N5). Default is a zero matrix.

- followup:

  Numeric scalar. Maximum follow-up (censoring) time. Defaults to `Inf`.

- lower:

  Numeric scalar. Lower bound for root-finding (inverse cumulative
  hazard) (default `1e-15`).

- upper:

  Numeric scalar. Upper bound for root-finding (default 200).

- gen_A0:

  Function. Function to generate the baseline treatment covariate
  A0.Takes N and L0 as inputs. Default is a Bernoulli(0.5) random
  variable.

- gen_L0:

  Function. Function to generate the baseline covariate L0. Takes N as
  input. Default is a N(0,1) random variable.

- add_cov:

  Named list of functions. Functions generating additional baseline
  covariates. Each function takes integer N and returns a numeric vector
  of length N. Default is NULL.

- at_risk:

  Function. Function determining if an individual is at risk for each
  event type, given their current event counts. Takes a numeric vector
  of event counts and returns a binary vector. Default returns 1 for all
  events.

- ...:

  Additional arguments passed to `simEventData`

## Value

A data frame containing the simulated data with columns:

- ID:

  Individual identifier

- Time:

  Time of the event

- Delta:

  Event type (0,...,5)

- L0:

  Baseline covariate

- A0:

  Baseline covariate

- L1,...Lp:

  Additional baseline covariates

## Examples

``` r
simDisease(10)
#> Key: <ID>
#>        ID      Time Delta         L0    A0     L
#>     <int>     <num> <int>      <num> <num> <num>
#>  1:     1 0.2320991     0 0.37199446     1     0
#>  2:     2 0.9325959     1 0.54061134     0     0
#>  3:     3 1.9954264     0 0.06705956     1     0
#>  4:     4 0.6763625     1 0.59677199     1     0
#>  5:     5 0.8183311     0 0.54246470     0     0
#>  6:     6 1.8132681     1 0.58750736     1     0
#>  7:     7 0.7422640     0 0.38016983     1     0
#>  8:     8 1.9995759     1 0.57360043     0     0
#>  9:     9 3.4658160     1 0.31303925     0     0
#> 10:    10 3.1104374     1 0.86595978     1     0
```
