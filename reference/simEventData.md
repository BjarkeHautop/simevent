# Simulate Continuous Time-to-Event Data with Multiple Event Types

`simEventData` simulates event times and types for a cohort of
individuals in a counting process framework. It supports multiple event
types (by default 4), including terminal events, with intensities
influenced by baseline covariates and previous event history.

## Usage

``` r
simEventData(
  N,
  beta = NULL,
  eta = NULL,
  nu = NULL,
  at_risk = NULL,
  term_deltas = c(0, 1),
  max_cens = Inf,
  add_cov = NULL,
  override_beta = NULL,
  max_events = 10,
  lower = 10^(-15),
  upper = 200,
  gen_A0 = NULL,
  gen_L0 = NULL,
  at_risk_cov = NULL,
  ...
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate.

- beta:

  Numeric matrix. Regression coefficients matrix where columns
  correspond to event types (N0, N1, ...) and rows correspond to
  covariates (L0, A0, L1, L2, ...) and event counts (N0, N1, ...). If
  `beta` has rownames, rows are matched by name against covariate/event
  names (any order, any subset; missing rows default to 0) instead of
  requiring a fixed row order. Default is a zero matrix.

- eta:

  Numeric vector. Shape parameters of the Weibull baseline intensity for
  each event type. Default is 0.1 for all events.

- nu:

  Numeric vector. Scale parameters of the Weibull baseline intensity for
  each event type. Default is 1.1 for all events.

- at_risk:

  Function. Function determining if an individual is at risk for each
  event type, given their current event counts. Takes a numeric vector
  of event counts and returns a binary vector. Default returns 1 for all
  events.

- term_deltas:

  Integer vector. Event types considered terminal (after which no
  further events occur). Default is c(0, 1).

- max_cens:

  Numeric. Maximum censoring time. Events occurring after this time are
  censored. Default is Inf (no maximal censoring).

- add_cov:

  Named list of functions. Functions generating baseline covariates,
  drawn in list order after `L0`/`A0` (unless the list itself supplies
  "L0"/"A0", replacing the defaults). Each function takes integer N and,
  optionally, any subset of the names of covariates defined earlier
  (including L0/A0), matched by argument name, and returns a numeric
  vector of length N. Default is NULL.

- override_beta:

  Named list. Used to specify entries of the `beta` matrix to override
  defaults. For example, `list("L0" = c("N1" = 2))` sets the effect of
  L0 on N1 to 2.

- max_events:

  Integer. Maximum number of events to simulate per individual. Default
  is 10.

- lower:

  Numeric. Lower bound for root-finding in inverse cumulative hazard
  calculations. Default is \\10^{-15}\\.

- upper:

  Numeric. Upper bound for root-finding in inverse cumulative hazard
  calculations. Default is 200.

- gen_A0:

  Function. Deprecated; use `add_cov = list(A0 = ...)` instead. Function
  to generate the baseline treatment covariate A0. Takes N and L0 as
  inputs. Default is a Bernoulli(0.5) random variable.

- gen_L0:

  Function. Deprecated; use `add_cov = list(L0 = ...)` instead. Function
  to generate the baseline covariate L0. Takes N as inputs. Default is a
  Uniform(0,1) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a matrix of covariates and
  returns a binary matrix. Default returns 1 for all events and all
  individuals.

- ...:

  Additional technical arguments.

## Value

A `data.table` with columns:

- ID:

  Individual identifier

- Time:

  Time of event

- Delta:

  Event type at time

- L0:

  Baseline covariate

- A0:

  Baseline treatment

- L1, L2, ...:

  Additional baseline covariates if specified

- N0, N1, ...:

  Event counts up to the current event

## Details

The event intensities for event type \\x\\ at time \\t\\ are given by
\$\$ \lambda^x(t) = \lambda_0^x(t) \exp(\beta_x^T L), \$\$ where the
baseline intensity follows a Weibull hazard function: \$\$
\lambda_0^x(t) = \eta^x \nu^x t^{\nu^x - 1}. \$\$ Here, \\L\\ is the
vector of covariates and event counts, and \\\beta^x\\ is the vector of
coefficients representing the effect of covariates and previous events
on the intensity.

Every simulated dataset includes two baseline covariates, `L0` (a
baseline covariate, Uniform(0,1) by default) and `A0` (a baseline
treatment indicator, Bernoulli(0.5) by default), followed by any
covariates supplied via `add_cov`. `L0`/`A0` are just the first two
entries of the covariate-generation list: a generator may depend on any
covariate defined earlier in that list by name (e.g. the default `A0`
generator takes `L0` as an argument), so `add_cov` can itself supply
"L0"/"A0" entries, or later covariates conditional on earlier ones (see
`add_cov` below).

## Examples

``` r
# Simulate data for 10 individuals with default settings
sim_data <- simEventData(N = 10)
head(sim_data)
#> Key: <ID>
#>       ID      Time Delta         L0    A0    N0    N1    N2    N3
#>    <int>     <num> <int>      <num> <num> <num> <num> <num> <num>
#> 1:     1 0.7685405     3 0.96263514     1     0     0     0     1
#> 2:     1 3.9906223     2 0.96263514     1     0     0     1     1
#> 3:     1 6.7972661     0 0.96263514     1     1     0     1     1
#> 4:     2 0.9621105     1 0.01141535     0     0     1     0     0
#> 5:     3 3.9906696     0 0.24988251     0     1     0     0     0
#> 6:     4 0.2759365     2 0.21641406     1     0     0     1     0
```
