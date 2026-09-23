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
#>        ID        Time Delta         L0     A     L
#>     <int>       <num> <int>      <num> <num> <num>
#>  1:     1  1.51216202     2 0.84000818     1     0
#>  2:     1  2.23639177     3 0.84000818     1     1
#>  3:     1  8.67567060     1 0.84000818     1     1
#>  4:     2  1.70286226     2 0.03308578     1     0
#>  5:     2  6.73507088     3 0.03308578     1     1
#>  6:     2 20.46830128     0 0.03308578     1     1
#>  7:     3  5.89363307     2 0.22492050     1     0
#>  8:     3  9.13428421     0 0.22492050     1     0
#>  9:     4  0.25701200     2 0.58185912     1     0
#> 10:     4  3.60155561     3 0.58185912     1     1
#> 11:     4  4.34737903     0 0.58185912     1     1
#> 12:     5  0.08181358     1 0.55046058     0     0
#> 13:     6  1.38547842     2 0.36495008     1     0
#> 14:     6  4.15217637     1 0.36495008     1     0
#> 15:     7  0.07178860     3 0.80168056     0     1
#> 16:     7  0.17267466     1 0.80168056     0     1
#> 17:     8  0.50941998     2 0.49029575     1     0
#> 18:     8  1.19568729     0 0.49029575     1     0
#> 19:     9  2.54577230     2 0.13689095     1     0
#> 20:     9 11.45403302     3 0.13689095     1     1
#> 21:     9 11.94137732     0 0.13689095     1     1
#> 22:    10  3.73694156     3 0.12309058     0     1
#> 23:    10  4.69795133     2 0.12309058     1     1
#> 24:    10  5.23029269     1 0.12309058     1     1
#>        ID        Time Delta         L0     A     L
#>     <int>       <num> <int>      <num> <num> <num>
```
