# Define an Effect for `sim_model()`

Multiplies the hazard of process `to` by `exp(coef * from)`.

## Usage

``` r
sim_effect(from, to, coef)
```

## Arguments

- from:

  Character. A covariate name (its value), a process name (its number of
  events so far), or an R expression of these. Expressions may also use:

  `t`

  :   The current time (see
      [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)'s
      `time_step`).

  `T_<proc>.<k>`

  :   Time of `proc`'s `k`-th event, `0` if it hasn't happened yet, e.g.
      `T_operation.1`. Multiply by the event count, as in
      `operation * f(t - T_operation.1)`, so the effect only applies
      once the event has happened.

  `last_time(proc)`

  :   Time of `proc`'s latest event, `-Inf` if none.

- to:

  Character. Name of the affected process.

- coef:

  Numeric. Cox-type coefficient.

## Value

An object of class `sim_effect`, for use in
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md).

## See also

[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

## Examples

``` r
sim_effect("age", "death", coef = 0.03)
#> $from
#> [1] "age"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 0.03
#> 
#> attr(,"class")
#> [1] "sim_effect"
sim_effect("(age - 60)^2", "death", coef = 0.001)
#> $from
#> [1] "(age - 60)^2"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 0.001
#> 
#> attr(,"class")
#> [1] "sim_effect"
sim_effect("relapse == 3", "death", coef = 1.2)
#> $from
#> [1] "relapse == 3"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 1.2
#> 
#> attr(,"class")
#> [1] "sim_effect"
sim_effect("t - last_time(checkup) < 1", "death", coef = 0.5)
#> $from
#> [1] "t - last_time(checkup) < 1"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 0.5
#> 
#> attr(,"class")
#> [1] "sim_effect"
sim_effect("operation * (t - T_operation.1)", "death", coef = 0.1)
#> $from
#> [1] "operation * (t - T_operation.1)"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 0.1
#> 
#> attr(,"class")
#> [1] "sim_effect"
sim_effect("operation * exp(-(t - T_operation.1))", "death", coef = 2)
#> $from
#> [1] "operation * exp(-(t - T_operation.1))"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 2
#> 
#> attr(,"class")
#> [1] "sim_effect"
```
