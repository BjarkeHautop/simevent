# Simulate Event Data from a "Drop In" Setting

`simDropIn` simulates data corresponding to `N` individuals that are at
risk for 4 or 5 events: Censoring (C), Death (D), Drop In Initiation
(Z), Change in Covariate Process (L), and optionally Treatment (A).

## Usage

``` r
simDropIn(
  N,
  eta = c(0.5, 0.5, 0.1, 0.25),
  nu = c(1.1, 1.1, 1.1, 1.1),
  adherence = FALSE,
  followup = Inf,
  cens = 1,
  generate.A0 = function(N, L0) stats::rbinom(N, 1, 0.5),
  lower = 1e-200,
  upper = 1e+10,
  t_prime = NULL,
  at_risk_cov = NULL,
  beta_L_A = 1,
  beta_L_Z = 2,
  beta_L_D = 1.5,
  beta_L_C = 0,
  beta_A_L = -0.5,
  beta_A_Z = -0.5,
  beta_A_D = -1,
  beta_A_C = 0,
  beta_Z_L = -1,
  beta_Z_A = 0,
  beta_Z_D = -1,
  beta_Z_C = 0,
  beta_L0_L = 1,
  beta_L0_A = 1,
  beta_L0_Z = 1,
  beta_L0_D = 1,
  beta_L0_C = 0,
  beta_A0_L = -1.5,
  beta_A0_A = 0,
  beta_A0_Z = 0,
  beta_A0_D = -2,
  beta_A0_C = 0,
  beta_L_A_prime = 0,
  beta_L_Z_prime = 0,
  beta_L_D_prime = 0,
  beta_L_C_prime = 0,
  beta_A_L_prime = 0,
  beta_A_Z_prime = 0,
  beta_A_D_prime = 0,
  beta_A_C_prime = 0,
  beta_Z_L_prime = 0,
  beta_Z_A_prime = 0,
  beta_Z_D_prime = 0,
  beta_Z_C_prime = 0,
  beta_L0_L_prime = 0,
  beta_L0_A_prime = 0,
  beta_L0_Z_prime = 0,
  beta_L0_D_prime = 0,
  beta_L0_C_prime = 0,
  beta_A0_L_prime = 0,
  beta_A0_A_prime = 0,
  beta_A0_Z_prime = 0,
  beta_A0_D_prime = 0,
  beta_A0_C_prime = 0,
  ...
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate.

- eta:

  Numeric vector of length 4 (or 5). Shape parameters of the Weibull
  baseline intensity for each event type. \$\$\eta \nu t^{\nu - 1}\$\$.

- nu:

  Numeric vector of length 4 (or 5). Scale parameters for the Weibull
  hazard.

- adherence:

  Logical. Indicator of whether a Treatment process should be simulated.

- followup:

  Numeric. Maximum censoring time. Events occurring after this time are
  censored. Default is Inf (no censoring).

- cens:

  Logical. Indicator of whether there should be a censoring process.

- generate.A0:

  Function. Function to generate the baseline treatment covariate A0.
  Takes N and L0 as inputs. Default is a Bernoulli(0.5) random variable.

- lower:

  Numeric. Lower bound for root-finding in inverse cumulative hazard
  calculations. Default is \\10^{-15}\\.

- upper:

  Numeric. Upper bound for root-finding in inverse cumulative hazard
  calculations. Default is 200.

- t_prime:

  Numeric scalar or NULL. Time point where effects change (optional).

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a numeric vector covariates
  and returns a binary vector. Default returns 1 for all events.

- beta_L_A:

  Numeric. Specifies how L affects A.

- beta_L_Z:

  Numeric. Specifies how L affects Z.

- beta_L_D:

  Numeric. Specifies how L affects D.

- beta_L_C:

  Numeric. Specifies how L affects C.

- beta_A_L:

  Numeric. Specifies how A affects L.

- beta_A_Z:

  Numeric. Specifies how A affects Z.

- beta_A_D:

  Numeric. Specifies how A affects D.

- beta_A_C:

  Numeric. Specifies how A affects C.

- beta_Z_L:

  Numeric. Specifies how Z affects L.

- beta_Z_A:

  Numeric. Specifies how Z affects A.

- beta_Z_D:

  Numeric. Specifies how Z affects D.

- beta_Z_C:

  Numeric. Specifies how Z affects C.

- beta_L0_L:

  Numeric. Specifies how L0 affects L.

- beta_L0_A:

  Numeric. Specifies how L0 affects A.

- beta_L0_Z:

  Numeric. Specifies how L0 affects Z.

- beta_L0_D:

  Numeric. Specifies how L0 affects D.

- beta_L0_C:

  Numeric. Specifies how L0 affects C.

- beta_A0_L:

  Numeric. Specifies how A0 affects L.

- beta_A0_A:

  Numeric. Specifies how A0 affects A.

- beta_A0_Z:

  Numeric. Specifies how A0 affects Z.

- beta_A0_D:

  Numeric. Specifies how A0 affects D.

- beta_A0_C:

  Numeric. Specifies how A0 affects C.

- beta_L_A_prime:

  Numeric. Specifies how L additionally affects A after time t_prime.

- beta_L_Z_prime:

  Numeric. Specifies how L additionally affects Z after time t_prime.

- beta_L_D_prime:

  Numeric. Specifies how L additionally affects D after time t_prime.

- beta_L_C_prime:

  Numeric. Specifies how L additionally affects C after time t_prime.

- beta_A_L_prime:

  Numeric. Specifies how A additionally affects L after time t_prime.

- beta_A_Z_prime:

  Numeric. Specifies how A additionally affects Z after time t_prime.

- beta_A_D_prime:

  Numeric. Specifies how A additionally affects D after time t_prime.

- beta_A_C_prime:

  Numeric. Specifies how A additionally affects C after time t_prime.

- beta_Z_L_prime:

  Numeric. Specifies how Z additionally affects L after time t_prime.

- beta_Z_A_prime:

  Numeric. Specifies how Z additionally affects A after time t_prime.

- beta_Z_D_prime:

  Numeric. Specifies how Z additionally affects D after time t_prime.

- beta_Z_C_prime:

  Numeric. Specifies how Z additionally affects C after time t_prime.

- beta_L0_L_prime:

  Numeric. Specifies how L0 additionally affects L after time t_prime.

- beta_L0_A_prime:

  Numeric. Specifies how L0 additionally affects A after time t_prime.

- beta_L0_Z_prime:

  Numeric. Specifies how L0 additionally affects Z after time t_prime.

- beta_L0_D_prime:

  Numeric. Specifies how L0 additionally affects D after time t_prime.

- beta_L0_C_prime:

  Numeric. Specifies how L0 additionally affects C after time t_prime.

- beta_A0_L_prime:

  Numeric. Specifies how A0 additionally affects L after time t_prime.

- beta_A0_A_prime:

  Numeric. Specifies how A0 additionally affects A after time t_prime.

- beta_A0_Z_prime:

  Numeric. Specifies how A0 additionally affects Z after time t_prime.

- beta_A0_D_prime:

  Numeric. Specifies how A0 additionally affects D after time t_prime.

- beta_A0_C_prime:

  Numeric. Specifies how A0 additionally affects C after time t_prime.

- ...:

  Additional arguments passed to `simEventData` or `simEventTV`.

## Value

A data frame containing the simulated event history data.

## Examples

``` r
simDropIn(10)
#> Key: <ID>
#>        ID      Time Delta        L0    A0     Z     L
#>     <int>     <num> <int>     <num> <num> <num> <num>
#>  1:     1 0.1899476     0 0.5608625     0     0     0
#>  2:     2 0.2442155     3 0.7927841     0     0     1
#>  3:     2 0.5342961     1 0.7927841     0     0     1
#>  4:     3 0.3557387     1 0.6886843     0     0     0
#>  5:     4 0.2827848     1 0.9364770     0     0     0
#>  6:     5 0.1476759     1 0.7032678     0     0     0
#>  7:     6 0.4831811     1 0.4719628     0     0     0
#>  8:     7 0.5320885     0 0.4179532     1     0     0
#>  9:     8 0.6300782     0 0.8821959     0     0     0
#> 10:     9 1.1491006     1 0.5140079     1     0     0
#> 11:    10 0.1260241     0 0.9386736     0     0     0
```
