# Define an Effect for `sim_graph()`

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
      [`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md)'s
      `time_step`).

  `last_time(proc)`

  :   Time of `proc`'s latest event, `-Inf` if none.

  `nth_time(proc, k)`

  :   Time of `proc`'s `k`-th event, `Inf` if fewer than `k`.

- to:

  Character. Name of the affected process.

- coef:

  Numeric. Cox-type coefficient.

## Value

An object of class `sim_effect`, for use in
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)

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
sim_effect("age^2", "death", coef = -0.001)
#> $from
#> [1] "age^2"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] -0.001
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
sim_effect("t >= nth_time(relapse, 3)", "death", coef = 0.8)
#> $from
#> [1] "t >= nth_time(relapse, 3)"
#> 
#> $to
#> [1] "death"
#> 
#> $coef
#> [1] 0.8
#> 
#> attr(,"class")
#> [1] "sim_effect"
```
