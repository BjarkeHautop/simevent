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

  Numeric. Additional effect of covariate `L = 1` on treatment hazard.
  Default 0.

- beta_L_D_prime:

  Numeric. Additionalffect of covariate `L = 1` on death hazard. Default
  0.

- beta_A_D_prime:

  Numeric. Effect of treatment `A = 1` on death hazard. Default 0.

- beta_A_L_prime:

  Numeric. Effect of treatment `A = 1` on covariate hazard. Default 0.

- beta_L0_A_prime:

  Numeric. Effect of baseline covariate `L0` on treatment hazard.
  Default 0.

- beta_L0_L_prime:

  Numeric. Effect of baseline covariate `L0` on covariate hazard.
  Default 0.

- beta_L0_D_prime:

  Numeric. Effect of baseline covariate `L0` on death hazard. Default 0.

- beta_L0_C_prime:

  Numeric. Effect of baseline covariate `L0` on censoring hazard.
  Default 0.

- beta_L_C_prime:

  Numeric. Effect of covariate `L = 1` on censoring hazard. Default 0.

- beta_A_C_prime:

  Numeric. Effect of treatment `A = 1` on censoring hazard. Default 0.

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

  Additional arguments passed to `simEventData` or `simEventTV`

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
#>  1:     1 1.53256297     2 0.7580909     1     0
#>  2:     1 6.98660338     0 0.7580909     1     0
#>  3:     2 0.14018602     1 0.3821143     0     0
#>  4:     3 3.56436629     3 0.4138130     0     1
#>  5:     3 5.02476838     2 0.4138130     1     1
#>  6:     3 6.16695688     1 0.4138130     1     1
#>  7:     4 0.93354610     2 0.9349064     1     0
#>  8:     4 3.08745012     3 0.9349064     1     1
#>  9:     4 3.15668020     1 0.9349064     1     1
#> 10:     5 0.09838135     2 0.3306358     1     0
#> 11:     5 4.33650702     0 0.3306358     1     0
#> 12:     6 3.07541193     2 0.4048474     1     0
#> 13:     6 4.43555920     0 0.4048474     1     0
#> 14:     7 1.38239335     2 0.9920628     1     0
#> 15:     7 3.46659619     0 0.9920628     1     0
#> 16:     8 0.47887780     0 0.5573049     0     0
#> 17:     9 1.89601825     2 0.2076326     1     0
#> 18:     9 2.67074072     3 0.2076326     1     1
#> 19:     9 8.37313290     1 0.2076326     1     1
#> 20:    10 1.44107185     3 0.8384938     0     1
#> 21:    10 3.37496772     1 0.8384938     0     1
#>        ID       Time Delta        L0     A     L
#>     <int>      <num> <int>     <num> <num> <num>
```
