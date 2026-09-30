# Simulate Data in a Disease Setting

`simDisease()` is deprecated as of simevent 0.2.0. Use
[`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md)
instead.

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

  Function. Deprecated; use `add_cov = list(A0 = ...)` instead. Function
  to generate the baseline treatment covariate A0. Takes N and L0 as
  inputs. Default is a Bernoulli(0.5) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a matrix of covariates and
  returns a binary matrix. Default returns 1 for all events and all
  individuals.

- ...:

  Additional arguments passed to `simEventData` or `simEventTV`.

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

Simulates event data representing three event types: Censoring (0),
Death (1), and Change in Covariate Process (2). Death and Censoring are
terminal events, while Change in Covariate Process can occur only once.
Event intensities depend on covariates and previous events, following
Weibull hazards with shape and scale parameters \\\eta\\ and \\\nu\\.

The arguments `beta_X_Y` control how X affects Y. A positive value means
that a higher value of X increases the intensity of Y, while a negative
value decreases the intensity. Time-varying effects can be included via
`beta_L_D_t_prime` and `t_prime`.

## Examples

``` r
simDisease(10)
#> Warning: `simDisease()` was deprecated in simevent 0.2.0.
#> ℹ Please use `sim_event_graph()` instead.
#> Key: <ID>
#>        ID       Time Delta        L0    A0     L
#>     <int>      <num> <int>     <num> <num> <num>
#>  1:     1 1.70766020     2 0.8713111     1     1
#>  2:     1 3.65762894     1 0.8713111     1     1
#>  3:     2 1.06445313     2 0.8427792     0     1
#>  4:     2 2.39412873     0 0.8427792     0     1
#>  5:     3 3.80699208     2 0.5846733     0     1
#>  6:     3 5.49992537     1 0.5846733     0     1
#>  7:     4 1.53826788     1 0.8195638     1     0
#>  8:     5 2.52110909     1 0.7748722     0     0
#>  9:     6 1.55072375     1 0.8291892     0     0
#> 10:     7 3.41081449     2 0.2580890     0     1
#> 11:     7 4.19517566     1 0.2580890     0     1
#> 12:     8 0.06626588     2 0.7470290     0     1
#> 13:     8 2.56621946     0 0.7470290     0     1
#> 14:     9 3.00139532     1 0.9934259     0     0
#> 15:    10 1.98943166     2 0.7537237     1     1
#> 16:    10 2.04684101     1 0.7537237     1     1
```
