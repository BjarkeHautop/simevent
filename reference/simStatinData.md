# Simulate Data in a Statin Setting

Simulates event history data in a statin treatment setting via
`simEventData`, with defaults for age (`A0`), a binary baseline
covariate (`L0`), and 12 event processes.

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
  t^{\nu - 1}\\. Defaults to `rep(0.025, 12)`.

- nu:

  Numeric vector of length equal to number of processes. Scale
  parameters for the Weibull hazards. Defaults to `rep(1.1, 12)`.

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

  Function. Function to generate the baseline treatment covariate A0.
  Takes N and L0 as inputs. Default is age, drawn as
  `Exponential(0.3) + 70` capped at 100.

- gen_L0:

  Function. Function to generate the baseline covariate L0. Takes N as
  input. Default is a Bernoulli(0.4) random variable.

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
simStatinData(10)
#> Key: <ID>
#>        ID      Time Delta    L0       A0    N0    N1    N2    N3    N4    N5
#>     <int>     <num> <int> <num>    <num> <num> <num> <num> <num> <num> <num>
#>  1:     1 4.5401173     7     1 73.55001     0     0     0     0     0     0
#>  2:     1 5.0000000     0     1 73.55001     1     0     0     0     0     0
#>  3:     2 0.4149360     5     0 70.81898     0     0     0     0     0     1
#>  4:     2 1.4224214    11     0 70.81898     0     0     0     0     0     1
#>  5:     2 4.8796220     7     0 70.81898     0     0     0     0     0     1
#>  6:     2 5.0000000     0     0 70.81898     1     0     0     0     0     1
#>  7:     3 0.6204326     5     0 72.56287     0     0     0     0     0     1
#>  8:     3 1.7026126     3     0 72.56287     0     0     0     1     0     1
#>  9:     3 3.0377237     3     0 72.56287     0     0     0     2     0     1
#> 10:     3 5.0000000     0     0 72.56287     1     0     0     2     0     1
#> 11:     4 0.6492432     9     0 74.33295     0     0     0     0     0     0
#> 12:     4 5.0000000     0     0 74.33295     1     0     0     0     0     0
#> 13:     5 0.2331259     0     1 75.94237     1     0     0     0     0     0
#> 14:     6 0.6888628     6     0 71.33176     0     0     0     0     0     0
#> 15:     6 4.5023959     1     0 71.33176     0     1     0     0     0     0
#> 16:     7 1.9806641     0     1 76.62502     1     0     0     0     0     0
#> 17:     8 0.9035064     2     0 75.68919     0     0     1     0     0     0
#> 18:     9 5.0000000     0     1 72.06932     1     0     0     0     0     0
#> 19:    10 2.8127428     8     1 70.26848     0     0     0     0     0     0
#> 20:    10 2.8358377     1     1 70.26848     0     1     0     0     0     0
#>        ID      Time Delta    L0       A0    N0    N1    N2    N3    N4    N5
#>     <int>     <num> <int> <num>    <num> <num> <num> <num> <num> <num> <num>
#>        N6    N7    N8    N9   N10   N11
#>     <num> <num> <num> <num> <num> <num>
#>  1:     0     1     0     0     0     0
#>  2:     0     1     0     0     0     0
#>  3:     0     0     0     0     0     0
#>  4:     0     0     0     0     0     1
#>  5:     0     1     0     0     0     1
#>  6:     0     1     0     0     0     1
#>  7:     0     0     0     0     0     0
#>  8:     0     0     0     0     0     0
#>  9:     0     0     0     0     0     0
#> 10:     0     0     0     0     0     0
#> 11:     0     0     0     1     0     0
#> 12:     0     0     0     1     0     0
#> 13:     0     0     0     0     0     0
#> 14:     1     0     0     0     0     0
#> 15:     1     0     0     0     0     0
#> 16:     0     0     0     0     0     0
#> 17:     0     0     0     0     0     0
#> 18:     0     0     0     0     0     0
#> 19:     0     0     1     0     0     0
#> 20:     0     0     1     0     0     0
#>        N6    N7    N8    N9   N10   N11
#>     <num> <num> <num> <num> <num> <num>
```
