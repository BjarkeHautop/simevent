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
#>        ID       Time Delta    L0       A0    N0    N1    N2    N3    N4    N5
#>     <int>      <num> <int> <num>    <num> <num> <num> <num> <num> <num> <num>
#>  1:     1 1.28747796     7     1 73.55001     0     0     0     0     0     0
#>  2:     1 1.87869578    10     1 73.55001     0     0     0     0     0     0
#>  3:     1 2.76585826     3     1 73.55001     0     0     0     1     0     0
#>  4:     1 3.90280669     5     1 73.55001     0     0     0     1     0     1
#>  5:     1 4.74374497     8     1 73.55001     0     0     0     1     0     1
#>  6:     1 5.00000000     0     1 73.55001     1     0     0     1     0     1
#>  7:     2 0.11766678     5     0 70.81898     0     0     0     0     0     1
#>  8:     2 0.40336761    11     0 70.81898     0     0     0     0     0     1
#>  9:     2 0.78676308     6     0 70.81898     0     0     0     0     0     1
#> 10:     2 0.96898721     8     0 70.81898     0     0     0     0     0     1
#> 11:     2 1.34366076     8     0 70.81898     0     0     0     0     0     1
#> 12:     2 1.64860689     4     0 70.81898     0     0     0     0     1     1
#> 13:     2 2.15771978     7     0 70.81898     0     0     0     0     1     1
#> 14:     2 2.29885923     0     0 70.81898     1     0     0     0     1     1
#> 15:     3 0.17594113     5     0 72.56287     0     0     0     0     0     1
#> 16:     3 0.48282369     3     0 72.56287     0     0     0     1     0     1
#> 17:     3 1.54985100     9     0 72.56287     0     0     0     1     0     1
#> 18:     3 1.70248968     6     0 72.56287     0     0     0     1     0     1
#> 19:     3 1.73511928     2     0 72.56287     0     0     1     1     0     1
#> 20:     4 0.18411118     9     0 74.33295     0     0     0     0     0     0
#> 21:     4 1.64096769     9     0 74.33295     0     0     0     0     0     0
#> 22:     4 2.92911728     0     0 74.33295     1     0     0     0     0     0
#> 23:     5 0.06610941     0     1 75.94237     1     0     0     0     0     0
#> 24:     6 0.19534642     6     0 71.33176     0     0     0     0     0     0
#> 25:     6 1.27678102     1     0 71.33176     0     1     0     0     0     0
#> 26:     7 0.56167303     0     1 76.62502     1     0     0     0     0     0
#> 27:     8 0.25621467     2     0 75.68919     0     0     1     0     0     0
#> 28:     9 1.93308150     8     1 72.06932     0     0     0     0     0     0
#> 29:     9 2.07866976     1     1 72.06932     0     1     0     0     0     0
#> 30:    10 0.79763233     8     1 70.26848     0     0     0     0     0     0
#> 31:    10 0.80418156     5     1 70.26848     0     0     0     0     0     1
#> 32:    10 1.19382958     3     1 70.26848     0     0     0     1     0     1
#> 33:    10 1.22369494     8     1 70.26848     0     0     0     1     0     1
#> 34:    10 2.65594862     0     1 70.26848     1     0     0     1     0     1
#>        ID       Time Delta    L0       A0    N0    N1    N2    N3    N4    N5
#>     <int>      <num> <int> <num>    <num> <num> <num> <num> <num> <num> <num>
#>        N6    N7    N8    N9   N10   N11
#>     <num> <num> <num> <num> <num> <num>
#>  1:     0     1     0     0     0     0
#>  2:     0     1     0     0     1     0
#>  3:     0     1     0     0     1     0
#>  4:     0     1     0     0     1     0
#>  5:     0     1     1     0     1     0
#>  6:     0     1     1     0     1     0
#>  7:     0     0     0     0     0     0
#>  8:     0     0     0     0     0     1
#>  9:     1     0     0     0     0     1
#> 10:     1     0     1     0     0     1
#> 11:     1     0     2     0     0     1
#> 12:     1     0     2     0     0     1
#> 13:     1     1     2     0     0     1
#> 14:     1     1     2     0     0     1
#> 15:     0     0     0     0     0     0
#> 16:     0     0     0     0     0     0
#> 17:     0     0     0     1     0     0
#> 18:     1     0     0     1     0     0
#> 19:     1     0     0     1     0     0
#> 20:     0     0     0     1     0     0
#> 21:     0     0     0     2     0     0
#> 22:     0     0     0     2     0     0
#> 23:     0     0     0     0     0     0
#> 24:     1     0     0     0     0     0
#> 25:     1     0     0     0     0     0
#> 26:     0     0     0     0     0     0
#> 27:     0     0     0     0     0     0
#> 28:     0     0     1     0     0     0
#> 29:     0     0     1     0     0     0
#> 30:     0     0     1     0     0     0
#> 31:     0     0     1     0     0     0
#> 32:     0     0     1     0     0     0
#> 33:     0     0     2     0     0     0
#> 34:     0     0     2     0     0     0
#>        N6    N7    N8    N9   N10   N11
#>     <num> <num> <num> <num> <num> <num>
```
