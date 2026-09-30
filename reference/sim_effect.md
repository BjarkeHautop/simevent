# Define an Effect for `sim_graph()`

An effect is a directed, weighted edge from a baseline covariate or
process to a process's intensity: multiplying that process's baseline
hazard by `exp(coef * from)`, where `from`'s value is either looked up
directly (a covariate's drawn value, or a process's current event count)
or, for anything not naming a single node, evaluated as an R expression.

## Usage

``` r
sim_effect(from, to, coef)
```

## Arguments

- from:

  Character. The name of a covariate,
  [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  covariate, or process defined in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call, or an R expression referencing them (see Details).

- to:

  Character. Name of a process defined in the same
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  call.

- coef:

  Numeric. Cox-type coefficient.

## Value

An object of class `sim_effect`, for use in
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

## Details

`from` may be:

- A bare node name:

  e.g. `"age"` or `"relapse"`: the covariate's drawn value, or the
  process's current cumulative event count.

- Any other R expression:

  parsed and evaluated per individual against every covariate/process
  name in the graph (by value, as above), plus:

  `t`

  :   The current time in the individual's risk interval.

  `last_time(proc)`

  :   Time of `proc`'s most recent occurrence so far, or `-Inf` if it
      hasn't occurred yet.

  `nth_time(proc, k)`

  :   Time of `proc`'s `k`-th occurrence so far, or `Inf` if fewer than
      `k` have happened yet. So e.g. `"t >= nth_time(relapse, 3)"` is
      simply `FALSE` until it applies.

  `proc` is written unquoted, the same as any other node name in the
  expression (e.g. `"t - last_time(checkup) < 1"`). Covers thresholds
  (`"relapse == 3"`), interactions (`"age * relapse"`), and nonlinear
  transforms (`"age^2"`) inline, without predefining a
  [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  covariate for them.

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

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
