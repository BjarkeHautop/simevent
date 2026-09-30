# Simulate Event History Data from a Generic Process Specification

`sim.generic()` is deprecated as of simevent 0.2.0. Use
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)
instead.

## Usage

``` r
sim.generic(
  baseline = list(),
  processes = list(),
  effects = list(),
  sim.object = list(),
  cens = 1,
  alpha.intervention = list(),
  baseline.intervention = list(),
  n = 500,
  browse = FALSE
)
```

## Arguments

- baseline:

  Named list of baseline covariate generator functions, each taking `N`
  and returning a numeric vector of length `N`.

- processes:

  Named list of process specifications. Each entry is a list with at
  least a `type` (one of `"censoring"`, `"terminal"`, `"one.jump"`, or
  any other value for a recurrent process), and Weibull intensity
  parameters `eta`/`nu`.

- effects:

  List of `c(from, to, coefficient)` triples specifying Cox-type effects
  of a baseline covariate or process on another process's intensity.
  `from`/`to` are process or baseline covariate names, matching the
  names used in `baseline`/ `processes`.

- sim.object:

  Optional list with `baseline`/`processes`/ `effects` entries, used as
  a fallback when none of `baseline`, `processes`, or `effects` are
  supplied directly (so, for example, an empty `effects = list()` is
  honored as "no effects" rather than triggering the fallback).

- cens:

  Numeric. At-risk indicator scaling for the censoring process. Default
  1.

- alpha.intervention:

  Named list of multiplicative interventions on process intensities
  (`eta`), keyed by process name.

- baseline.intervention:

  Named list of interventions that fix a baseline covariate to a
  constant value, keyed by covariate name.

- n:

  Integer. Number of individuals to simulate. Default 500.

- browse:

  Logical. If `TRUE`, drop into
  [`browser()`](https://rdrr.io/r/base/browser.html) before simulating.
  Default `FALSE`.

## Value

A `data.table` of simulated event history data with columns `id`,
`time`, `delta`, the baseline covariates, and one column per
non-terminal process.

## Details

`sim.generic` simulates multistate event history data from a set of
user-specified baseline covariates, event processes (with Weibull
intensities and Cox-type effects), and their effects on one another, by
translating the specification into a
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)
and simulating from it.

Where the preset wrapper functions
([`simCRdata`](https://github.com/BjarkeHautop/simevent/reference/simCRdata.md),
[`simDisease`](https://github.com/BjarkeHautop/simevent/reference/simDisease.md),
[`simSurvData`](https://github.com/BjarkeHautop/simevent/reference/simSurvData.md),
etc.) hard-code a fixed set of processes and effects, `sim.generic` lets
you describe an arbitrary number of named processes and baseline
covariates directly.

## Examples

``` r
baseline <- list(L0 = function(N) rbinom(N, 1, 0.4))
processes <- list(
  censoring = list(type = "censoring", eta = 0.1, nu = 1.1),
  death = list(type = "terminal", eta = 0.1, nu = 1.1)
)
effects <- list(c("L0", "death", 1))
data <- sim.generic(baseline, processes, effects, n = 100)
#> Warning: `sim.generic()` was deprecated in simevent 0.2.0.
#> ℹ Please use `sim_graph()` instead.
head(data)
#> Key: <id>
#>       id       time delta    L0
#>    <int>      <num> <int> <int>
#> 1:     1  2.2735968     1     0
#> 2:     2  0.5792321     1     0
#> 3:     3  6.9642730     1     1
#> 4:     4 12.0749279     0     1
#> 5:     5  7.5603019     0     0
#> 6:     6  5.3536769     0     0
```
