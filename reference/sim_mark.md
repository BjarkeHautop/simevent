# Define a Time-Varying Covariate for `sim_model()`

`sim_mark` builds a covariate, such as a lab value measured at visits,
that is drawn at baseline and redrawn whenever one of the `update`
processes fires. It stays constant between those events. In
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
output, each row holds its value after that row's event, and a
`<name>_0` column holds its baseline value;
[`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md)'s
`mark_cols` turns these into the value in force during each interval.

## Usage

``` r
sim_mark(init, update, draw)
```

## Arguments

- init:

  Function of `N` giving the initial values, as for
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md).
  Covariates defined after the mark see its initial value.

- update:

  Character. Names of the `"transient"`
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)es
  whose events redraw the mark.

- draw:

  Function returning the new values. It may take `N` (number of
  individuals updated) and `lp` (their linear predictor, `0` if no
  effect goes into the mark).

## Value

An object of class `sim_mark`, for use in
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## Details

What a new value depends on is given by
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)s
with the mark as `to`: at each update, their `coef * from` terms are
summed into a linear predictor `lp` and passed to `draw`, e.g. as the
mean of [`stats::rnorm()`](https://rdrr.io/r/stats/Normal.html). Effects
are evaluated just after the triggering event, so they see process
counts and event times including it, `t` as its time, and the mark's own
value before the update. Marks updated by the same event are redrawn in
the order they are defined.

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md),
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)

## Examples

``` r
# Blood pressure measured at each visit, lowered by treatment and driving
# both treatment initiation and stroke:
model <- sim_model(
  age = sim_covariate(function(N) rnorm(N, mean = 60, sd = 10)),
  visit = sim_process("transient", eta = 1, nu = 1),
  bp = sim_mark(
    init = function(N, age) rnorm(N, 130 + 0.5 * (age - 60), 12),
    update = "visit",
    draw = function(N, lp) rnorm(N, mean = 130 + lp, sd = 6)
  ),
  treatment = sim_process("transient", eta = 0.05, nu = 1, limit = 1),
  stroke = sim_process("terminal", eta = 0.01, nu = 1.2),
  effects = list(
    sim_effect("bp - 130", "bp", coef = 0.8),
    sim_effect("treatment", "bp", coef = -2),
    sim_effect("bp - 130", "treatment", coef = 0.08),
    sim_effect("bp - 130", "stroke", coef = 0.03),
    sim_effect("treatment", "stroke", coef = -0.2)
  )
)
summary(model)
#> <sim_model> covariates
#>  name     kind
#>   age baseline
#>    bp     mark
#> 
#> <sim_model> processes
#>       name      type baseline  eta  nu limit
#>      visit transient  weibull 1.00 1.0   Inf
#>  treatment transient  weibull 0.05 1.0     1
#>     stroke  terminal  weibull 0.01 1.2   Inf
#> 
#> <sim_model> effects
#>         from        to  coef
#>  bp[k] - 130   bp[k+1]  0.80
#>    treatment   bp[k+1] -2.00
#>     bp - 130 treatment  0.08
#>     bp - 130    stroke  0.03
#>    treatment    stroke -0.20
#> 
#> mark[k]: value after the mark's k-th update (k = 0: init)
head(sim_events(model, n = 5, max_cens = 5), 10)
#> Key: <id>
#>        id      time    event      age       bp    bp_0 visit treatment
#>     <int>     <num>   <fctr>    <num>    <num>   <num> <num>     <num>
#>  1:     1 1.0561024    visit 55.59929 114.9236 121.870     1         0
#>  2:     1 1.8127053    visit 55.59929 134.1873 121.870     2         0
#>  3:     1 3.3220539    visit 55.59929 128.5783 121.870     3         0
#>  4:     1 5.0000000 max_cens 55.59929 128.5783 121.870     3         0
#>  5:     2 0.6605733    visit 74.35053 130.4290 137.916     1         0
#>  6:     2 2.7703674    visit 74.35053 134.3470 137.916     2         0
#>  7:     2 3.0560960    visit 74.35053 120.8801 137.916     3         0
#>  8:     2 4.1748935    visit 74.35053 124.7347 137.916     4         0
#>  9:     2 4.4951303    visit 74.35053 128.8170 137.916     5         0
#> 10:     2 5.0000000 max_cens 74.35053 128.8170 137.916     5         0
```
