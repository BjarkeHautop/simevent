# Simulate Event History Data with Treatment and Time-Dependent Covariate

Simulates event history data with four types of events representing
censoring (0), death (1), treatment (2), and covariate change (3). Death
and censoring are terminal events; treatment and covariate events can
occur only once.

## Usage

``` r
simTreatment(
  N,
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  beta_L_A = 1,
  beta_L_D = 1,
  beta_A_D = -1,
  beta_A_L = -0.5,
  beta_L0_A = 1,
  beta_L0_L = 1,
  beta_L0_D = 1,
  beta_L0_C = 0,
  beta_L_C = 0,
  beta_A_C = 0,
  beta_L_A_prime = 0,
  beta_L_D_prime = 0,
  beta_A_D_prime = 0,
  beta_A_L_prime = 0,
  beta_L0_A_prime = 0,
  beta_L0_L_prime = 0,
  beta_L0_D_prime = 0,
  beta_L0_C_prime = 0,
  beta_L_C_prime = 0,
  beta_A_C_prime = 0,
  t_prime = NULL,
  at_risk_cov = NULL,
  cens = 1,
  op = 1,
  lower = 10^(-15),
  upper = 200,
  followup = Inf,
  ...
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate.

- eta:

  Numeric vector of length 4. Shape parameters for Weibull intensities,
  parameterized as \\\eta \nu t^{\nu - 1}\\. Default is `rep(0.1, 4)`.

- nu:

  Numeric vector of length 4. Scale parameters for Weibull hazards.
  Default is `rep(1.1, 4)`.

- beta_L_A:

  Numeric. Effect of covariate `L = 1` on treatment hazard. Default 1.

- beta_L_D:

  Numeric. Effect of covariate `L = 1` on death hazard. Default 1.

- beta_A_D:

  Numeric. Effect of treatment `A = 1` on death hazard. Default -1.

- beta_A_L:

  Numeric. Effect of treatment `A = 1` on covariate hazard. Default
  -0.5.

- beta_L0_A:

  Numeric. Effect of baseline covariate `L0` on treatment hazard.
  Default 1.

- beta_L0_L:

  Numeric. Effect of baseline covariate `L0` on covariate hazard.
  Default 1.

- beta_L0_D:

  Numeric. Effect of baseline covariate `L0` on death hazard. Default 1.

- beta_L0_C:

  Numeric. Effect of baseline covariate `L0` on censoring hazard.
  Default 0.

- beta_L_C:

  Numeric. Effect of covariate `L = 1` on censoring hazard. Default 0.

- beta_A_C:

  Numeric. Effect of treatment `A = 1` on censoring hazard. Default 0.

- beta_L_A_prime:

  Numeric. Additional effect of covariate `L = 1` on treatment hazard
  after `t_prime`. Default 0.

- beta_L_D_prime:

  Numeric. Additional effect of covariate `L = 1` on death hazard after
  `t_prime`. Default 0.

- beta_A_D_prime:

  Numeric. Additional effect of treatment `A = 1` on death hazard after
  `t_prime`. Default 0.

- beta_A_L_prime:

  Numeric. Additional effect of treatment `A = 1` on covariate hazard
  after `t_prime`. Default 0.

- beta_L0_A_prime:

  Numeric. Additional effect of baseline covariate `L0` on treatment
  hazard after `t_prime`. Default 0.

- beta_L0_L_prime:

  Numeric. Additional effect of baseline covariate `L0` on covariate
  hazard after `t_prime`. Default 0.

- beta_L0_D_prime:

  Numeric. Additional effect of baseline covariate `L0` on death hazard
  after `t_prime`. Default 0.

- beta_L0_C_prime:

  Numeric. Additional effect of baseline covariate `L0` on censoring
  hazard after `t_prime`. Default 0.

- beta_L_C_prime:

  Numeric. Additional effect of covariate `L = 1` on censoring hazard
  after `t_prime`. Default 0.

- beta_A_C_prime:

  Numeric. Additional effect of treatment `A = 1` on censoring hazard
  after `t_prime`. Default 0.

- t_prime:

  Numeric scalar or NULL. Time point where effects change (optional).

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a numeric vector covariates
  and returns a binary vector. Default returns 1 for all events.

- cens:

  Integer (0 or 1). Indicates if censoring is possible. Default 1.

- op:

  Integer (0 or 1). Indicates if treatment (operation) is possible.
  Default 1.

- lower:

  Numeric. Lower bound for root finding (inverse cumulative hazard).
  Default `1e-15`.

- upper:

  Numeric. Upper bound for root finding (inverse cumulative hazard).
  Default 200.

- followup:

  Numeric. Maximum censoring time. Defaults to `Inf` (no censoring).

- ...:

  Additional arguments passed to `simEventData` or `simEventTV`.

## Value

A `data.frame` with columns:

- `ID` - Individual identifier.

- `Time` - Event time.

- `Delta` - Event type (0=censoring, 1=death, 2=treatment, 3=covariate
  change).

- `L0` - Baseline covariate.

- `L` - Time-dependent covariate.

- `A` - Treatment status.

## Details

Event intensities are modeled using Weibull hazards with parameters
\\\nu\\ (scale) and \\\eta\\ (shape), and covariate effects controlled
by specified `beta` parameters. For example, `beta_L_A` quantifies the
effect of covariate `L = 1` on the hazard of treatment.

## Examples

``` r
simTreatment(10)
#> Key: <ID>
#>        ID       Time Delta        L0     A     L
#>     <int>      <num> <int>     <num> <num> <num>
#>  1:     1 1.60937897     1 0.4013722     0     0
#>  2:     2 0.35047328     1 0.5286588     0     0
#>  3:     3 1.34003341     1 0.6417266     0     0
#>  4:     4 1.22361034     1 0.8901832     0     0
#>  5:     5 2.66686046     1 0.8172235     0     0
#>  6:     6 0.07611203     0 0.8504901     0     0
#>  7:     7 1.19170742     0 0.1950094     0     0
#>  8:     8 1.70857612     1 0.8698328     0     0
#>  9:     9 0.15932568     1 0.4123311     0     0
#> 10:    10 0.38013908     2 0.4366730     1     0
#> 11:    10 6.50400572     3 0.4366730     1     1
#> 12:    10 8.69130214     1 0.4366730     1     1
```
