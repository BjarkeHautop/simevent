# Define an Effect for `sim_model()`

For each term of `from`, adds `coef * term` to the linear predictor of
`to`: its log-hazard if `to` is a
[`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md),
or the `lp` passed to its `draw` if it's a
[`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md).

## Usage

``` r
sim_effect(formula, coef)
```

## Arguments

- formula:

  `to ~ from`, with `to` the affected process or mark. `from` is one or
  more terms separated by `+`; wrap a sum in parentheses to make it one
  term. A term is an R expression of covariates (their value) and
  processes (their number of events so far), which may also use:

  `t`

  :   The current time (see
      [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)'s
      `time_step`).

  [`event_time()`](https://github.com/BjarkeHautop/simevent/reference/event_time.md)

  :   Time of a process's `k`-th or `k`-th latest event.

  `<name>(s)`

  :   The value of covariate, mark or process count `name` at time `s`,
      after any update at `s`, e.g. `bp(event_time(operation, 1))`.

- coef:

  Numeric vector, one coefficient per term of `from`.

## Value

A `sim_effect`, for
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)'s
`effects`.

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
[`event_time()`](https://github.com/BjarkeHautop/simevent/reference/event_time.md)

## Examples

``` r
sim_effect(death ~ age, coef = 0.03)
#> <sim_effect> death ~ 0.03 * age
sim_effect(death ~ age + relapse, coef = c(0.03, 1))
#> <sim_effect> death ~ 0.03 * age + 1 * relapse
sim_effect(death ~ (age + bmi), coef = 0.02)
#> <sim_effect> death ~ 0.02 * (age + bmi)
sim_effect(death ~ (age - 60)^2 + (relapse == 3), coef = c(0.001, 1.2))
#> <sim_effect> death ~ 0.001 * ((age - 60)^2) + 1.2 * (relapse == 3)
sim_effect(death ~ checkup > 0 & t - event_time(checkup, -1) < 1, coef = 0.5)
#> <sim_effect> death ~ 0.5 * (checkup > 0 & t - event_time(checkup, -1) < 1)
sim_effect(death ~ operation * bp(event_time(operation, 1)), coef = 0.02)
#> <sim_effect> death ~ 0.02 * (operation * bp(event_time(operation, 1)))
```
