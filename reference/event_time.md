# Time of an Earlier Event

For use only inside a
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)
formula.

## Usage

``` r
event_time(proc, k)
```

## Arguments

- proc:

  Name of a process in the model, unquoted.

- k:

  Whole number other than `0`: the `k`-th event, or if negative, the
  `abs(k)`-th latest (`-1` is the latest).

## Value

The event's time, or `0` if there are fewer than `abs(k)` events so far.
Multiply by the event count, as in
`operation * f(t - event_time(operation, 1))`, so the effect only
applies once the event has happened.

## See also

[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)

## Examples

``` r
sim_effect(
  death ~ operation * exp(-(t - event_time(operation, 1))),
  coef = 2
)
#> <sim_effect> death ~ 2 * (operation * exp(-(t - event_time(operation, 1))))
sim_effect(death ~ visit > 0 & t - event_time(visit, -1) < 1, coef = 0.5)
#> <sim_effect> death ~ 0.5 * (visit > 0 & t - event_time(visit, -1) < 1)
sim_effect(death ~ visit >= 3 & t - event_time(visit, -3) < 1, coef = 1)
#> <sim_effect> death ~ 1 * (visit >= 3 & t - event_time(visit, -3) < 1)
```
