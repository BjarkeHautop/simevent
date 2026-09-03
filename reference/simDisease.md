# Simulate Data in a Disease Setting

This function simulates event data representing three event types:
Censoring (0), Death (1), and Change in Covariate Process (2). Death and
Censoring are terminal events, while Change in Covariate Process can
occur only once.

## Usage

``` r
simDisease(
  N,
  eta = rep(0.1, 3),
  nu = rep(1.1, 3),
  cens = 1,
  beta_L0_D = 1,
  beta_L0_L = 1,
  beta_L_D = 1,
  beta_A0_D = 0,
  beta_A0_L = 0,
  beta_L0_C = 0,
  beta_A0_C = 0,
  beta_L_C = 0,
  followup = Inf,
  lower = 10^(-15),
  upper = 200,
  beta_L_D_t_prime = NULL,
  t_prime = NULL,
  gen_A0 = NULL,
  at_risk_cov = NULL,
  ...
)
```

## Arguments

- N:

  Numeric scalar. Number of individuals to simulate.

- eta:

  Numeric vector of length 3. Shape parameters for Weibull intensities
  with parameterization \\\eta \nu t^{\nu - 1}\\. Defaults to
  `rep(0.1, 3)`.

- nu:

  Numeric vector of length 3. Scale parameters for the Weibull hazards.
  Defaults to `rep(1.1, 3)`.

- cens:

  Binary scalar. Indicates whether individuals are at risk of censoring
  (default `1`).

- beta_L0_D:

  Numeric scalar. Effect of baseline covariate L0 on death risk (default
  1).

- beta_L0_L:

  Numeric scalar. Effect of baseline covariate L0 on covariate change
  risk (default 1).

- beta_L_D:

  Numeric scalar. Effect of covariate change (L = 1) on death risk
  (default 1).

- beta_A0_D:

  Numeric scalar. Effect of baseline treatment (A0 = 1) on death risk
  (default 0).

- beta_A0_L:

  Numeric scalar. Effect of baseline treatment (A0 = 1) on covariate
  change risk (default 0).

- beta_L0_C:

  Numeric scalar. Effect of baseline covariate L0 on censoring
  probability (default 0).

- beta_A0_C:

  Numeric scalar. Effect of baseline treatment A0 on censoring
  probability (default 0).

- beta_L_C:

  Numeric scalar. Effect of covariate change (L = 1) on censoring
  probability (default 0).

- followup:

  Numeric scalar. Maximum follow-up (censoring) time. Defaults to `Inf`.

- lower:

  Numeric scalar. Lower bound for root-finding (inverse cumulative
  hazard) (default `1e-15`).

- upper:

  Numeric scalar. Upper bound for root-finding (default 200).

- beta_L_D_t_prime:

  Numeric scalar or NULL. Additional effect of covariate change on death
  risk after time `t_prime` (optional).

- t_prime:

  Numeric scalar or NULL. Time point where effects change (optional).

- gen_A0:

  Function. Function to generate the baseline treatment covariate A0.
  Takes N and L0 as inputs. Default is a Bernoulli(0.5) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a numeric vector covariates
  and returns a binary vector. Default returns 1 for all events.

- ...:

  Additional arguments passed to `simEventData` or `simEventTV`

## Value

A data frame containing the simulated data with columns:

- ID:

  Individual identifier

- Time:

  Time of the event

- Delta:

  Event type (0 = censoring, 1 = death, 2 = covariate change)

- L0:

  Baseline covariate

- L:

  Covariate indicating change in covariate process

## Details

Event intensities depend on previous events and predefined parameters
\\\nu\\ and \\\eta\\.

The arguments `beta_X_Y` control how the X affects Y. A positive value
means that a higher value of X increases the intensity of Y, while a
negative value decreases the intensity.

The simulation uses an event history framework with terminal events
(death, censoring) and a single recurrent covariate change. The event
intensities depend on covariates and previous events according to
user-specified parameters. Time-varying effects can be included via
`beta_L_D_t_prime` and `t_prime`.

## Examples

``` r
simDisease(10)
#> Key: <ID>
#>        ID       Time Delta        L0    A0     L
#>     <int>      <num> <int>     <num> <num> <num>
#>  1:     1 2.21316247     2 0.5031158     1     1
#>  2:     1 2.67315265     1 0.5031158     1     1
#>  3:     2 4.09487739     2 0.2968534     0     1
#>  4:     2 6.39804291     1 0.2968534     0     1
#>  5:     3 9.86025281     1 0.2317255     0     0
#>  6:     4 0.08721161     1 0.5951929     0     0
#>  7:     5 0.74653349     1 0.9495907     0     0
#>  8:     6 1.01768854     1 0.6086446     1     0
#>  9:     7 1.12425645     1 0.5617409     1     0
#> 10:     8 5.25604931     2 0.8382615     0     1
#> 11:     8 9.26838927     1 0.8382615     0     1
#> 12:     9 2.52572316     1 0.3706584     0     0
#> 13:    10 5.74922441     0 0.2718674     0     0
```
