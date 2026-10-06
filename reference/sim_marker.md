# Define a Time-Varying Covariate for `sim_model()`

`sim_marker` builds a covariate, such as a lab value measured at visits,
that is drawn at baseline and redrawn whenever one of the `update`
processes fires. It stays constant between those events. In
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
output, each row holds its value after that row's event.

## Usage

``` r
sim_marker(init, update, draw)
```

## Arguments

- init:

  Function of `N` giving the initial values, as for
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md).
  Covariates defined after the marker see its initial value.

- update:

  Character. Names of the `"transient"`
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)es
  whose events redraw the marker.

- draw:

  Function returning the new values. It may take, by name: `N` (number
  of individuals updated), `t` (the event time), any covariate or marker
  (current value, including this marker's own), and any process (number
  of events so far, including the triggering event).

## Value

An object of class `sim_marker`, for use in
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)

## Examples

``` r
# Blood pressure measured at each visit, lowered by treatment and driving
# both treatment initiation and stroke:
model <- sim_model(
  age = sim_covariate(function(N) rnorm(N, mean = 60, sd = 10)),
  visit = sim_process("transient", eta = 1, nu = 1),
  bp = sim_marker(
    init = function(N, age) rnorm(N, 130 + 0.5 * (age - 60), 12),
    update = "visit",
    draw = function(N, bp, treatment) {
      rnorm(N, 0.8 * bp + 26 - 2 * treatment, 6)
    }
  ),
  treatment = sim_process("transient", eta = 0.05, nu = 1, limit = 1),
  stroke = sim_process("terminal", eta = 0.01, nu = 1.2),
  effects = list(
    sim_effect("bp - 130", "treatment", coef = 0.08),
    sim_effect("bp - 130", "stroke", coef = 0.03),
    sim_effect("treatment", "stroke", coef = -0.2)
  )
)
head(sim_events(model, n = 5, max_cens = 5), 10)
#> Key: <id>
#>        id      time    event      age       bp visit treatment
#>     <int>     <num>   <fctr>    <num>    <num> <num>     <num>
#>  1:     1 1.0561024    visit 55.59929 114.9236     1         0
#>  2:     1 1.8127053    visit 55.59929 134.1873     2         0
#>  3:     1 3.3220539    visit 55.59929 128.5783     3         0
#>  4:     1 5.0000000 max_cens 55.59929 128.5783     3         0
#>  5:     2 0.6605733    visit 74.35053 130.4290     1         0
#>  6:     2 2.7703674    visit 74.35053 134.3470     2         0
#>  7:     2 3.0560960    visit 74.35053 120.8801     3         0
#>  8:     2 4.1748935    visit 74.35053 124.7347     4         0
#>  9:     2 4.4951303    visit 74.35053 128.8170     5         0
#> 10:     2 5.0000000 max_cens 74.35053 128.8170     5         0
```
