# Simulate Event Data with Multiple Event Types and Covariates

Simulate Continuous Time-to-Event Data with Multiple Event Types

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
  covariates (L0, A0, L1, L2, ...) and event counts (N0, N1, ...).
  Default is a zero matrix.

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

  Named list of functions. Functions generating additional baseline
  covariates. Each function takes integer N and returns a numeric vector
  of length N. Default is NULL.

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

  Function. Function to generate the baseline treatment covariate A0.
  Takes N and L0 as inputs. Default is a Bernoulli(0.5) random variable.

- gen_L0:

  Function. Function to generate the baseline covariate L0. Takes N as
  inputs. Default is a N(0,1) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a matrix of covariates and
  returns a binary matrix vector. Default returns 1 for all events and
  all individuals.

- ...:

  Additional technical arguments

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

`simEventData` simulates event times and types for a cohort of
individuals in a counting process framework. It supports multiple event
types (by default 4), including terminal events, with intensities
influenced by baseline covariates and previous event history.

The event intensities for event type \\x\\ at time \\t\\ are given by
\$\$ \lambda^x(t) = \lambda_0^x(t) \exp(\beta_x^T L), \$\$ where the
baseline intensity follows a Weibull hazard function: \$\$
\lambda_0^x(t) = \eta^x \nu^x t^{\nu^x - 1}. \$\$ Here, \\L\\ is the
vector of covariates and event counts, and \\\beta^x\\ is the a vector
of coefficients representing the effect of covariates and previous
events on the intensity.

## Examples

``` r
# Simulate data for 10 individuals with default settings
sim_data <- simEventData(N = 10)
head(sim_data)
#> Key: <ID>
#>       ID     Time Delta         L0    A0    N0    N1    N2    N3
#>    <int>    <num> <int>      <num> <num> <num> <num> <num> <num>
#> 1:     1 1.950912     2 0.46717567     0     0     0     1     0
#> 2:     1 4.578772     0 0.46717567     0     1     0     1     0
#> 3:     2 2.007552     0 0.49895085     0     1     0     0     0
#> 4:     3 1.268429     3 0.69876955     1     0     0     0     1
#> 5:     3 1.387908     0 0.69876955     1     1     0     0     1
#> 6:     4 1.546615     3 0.07114061     0     0     0     0     1
```
