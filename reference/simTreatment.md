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
#>  1:     1 1.74522505     2 0.6369412     1     0
#>  2:     1 2.95102859     3 0.6369412     1     1
#>  3:     1 8.03530287     0 0.6369412     1     1
#>  4:     2 0.96656873     0 0.8269983     0     0
#>  5:     3 3.01052777     0 0.6959707     0     0
#>  6:     4 2.30196568     2 0.4015605     1     0
#>  7:     4 6.24327666     3 0.4015605     1     1
#>  8:     4 8.17661420     0 0.4015605     1     1
#>  9:     5 0.06978376     2 0.9964493     1     0
#> 10:     5 0.17099191     3 0.9964493     1     1
#> 11:     5 5.00649860     1 0.9964493     1     1
#> 12:     6 2.14498551     2 0.8034955     1     0
#> 13:     6 4.77570770     1 0.8034955     1     0
#> 14:     7 0.63252858     3 0.4721267     0     1
#> 15:     7 4.29389393     0 0.4721267     0     1
#> 16:     8 0.52453649     1 0.9792471     0     0
#> 17:     9 2.56599994     0 0.1035612     0     0
#> 18:    10 0.44059940     2 0.3355462     1     0
#> 19:    10 3.21423678     1 0.3355462     1     0
```
