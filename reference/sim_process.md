# Define an Event Process for `sim_graph()`

Define an Event Process for
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

## Usage

``` r
sim_process(
  type = c("censoring", "terminal", "transient"),
  eta,
  nu,
  limit = Inf
)
```

## Arguments

- type:

  What kind of process this is, and in particular whether it ends an
  individual's follow-up:

  `"censoring"`

  :   Right-censoring: ends follow-up, but isn't an outcome event. At
      most one per individual.

  `"terminal"`

  :   An absorbing outcome event (e.g. death, or one cause in a
      competing-risks setting): ends follow-up. At most one per
      individual.

  `"transient"`

  :   Doesn't end follow-up, and can fire more than once (up to `limit`
      times, default unlimited). Because follow-up continues, its
      running event count can itself be used as a time-varying
      [`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)
      `from` for other processes (e.g. a relapse process raising the
      hazard of a later terminal event).

- eta:

  Numeric. Weibull shape parameter of the process's baseline intensity.

- nu:

  Numeric. Weibull scale parameter of the process's baseline intensity.

- limit:

  Integer, or `Inf`. For `type = "transient"` only: the maximum number
  of times this process can fire. Default `Inf` (unlimited, i.e.
  recurrent); `limit = 1` gives a "one-jump" process (at most a single
  event). Ignored for other types.

## Value

An object of class `sim_process`, for use in
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md).

## See also

[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md),
[`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)
