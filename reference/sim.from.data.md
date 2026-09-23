# Simulate Event History Data from Parameters Fitted to Observed Data

`sim.from.data` simulates new multistate event history data using
process/baseline parameters previously estimated from observed data
(e.g. Weibull and Cox parameters extracted from `coxph` fits, as
[`simEventCox`](https://github.com/miclukacova/simevent/reference/simEventCox.md)
does with its `cox_fits` argument), via
[`simEventData`](https://github.com/miclukacova/simevent/reference/simEventData.md).

## Usage

``` r
sim.from.data(
  n = 500,
  sim.parameters,
  cens = 1,
  alpha.intervention = list(),
  baseline.intervention = list(),
  browse = FALSE,
  verbose = FALSE
)
```

## Arguments

- n:

  Integer. Number of individuals to simulate. Default 500.

- sim.parameters:

  Named list of fitted simulation parameters, with one entry per process
  plus a `baseline.summary` entry and a `model.structure` entry:

  - Each process entry (named after the process) is a list with
    `weibull.parameters` (a named numeric vector with entries whose
    names start with `"eta"` and `"nu"`) and `cox.parameters` (a named
    numeric vector of Cox coefficients, named after baseline covariates,
    other processes, or `"<covariate>=<level>"`-style names for
    categorical baseline effects).

  - `baseline.summary` is a named list, one entry per baseline
    covariate, each a list with a `type` (`"numeric"` or a
    factor/character class) and either `mean`/`sd` (for a continuous
    covariate), `mean` alone (for a 0/1 covariate, interpreted as a
    Bernoulli probability), or `proportions` (a named list/table of
    category probabilities).

  - `model.structure` is a list with `process.names`, `process.deltas`
    (numeric `delta` value for each process), and `process.types`
    (`"terminal"`, `"one.jump"`, or any other value for a recurrent
    process, one per process), plus `cens.process.id` (the index into
    `process.names` of the censoring process).

- cens:

  Numeric. At-risk indicator scaling for the censoring process. Default
  1.

- alpha.intervention:

  Named list of multiplicative interventions on process intensities
  (`eta`), keyed by process name.

- baseline.intervention:

  Named list of interventions that fix a baseline covariate to a
  constant value, keyed by covariate name.

- browse:

  Logical. If `TRUE`, drop into
  [`browser()`](https://rdrr.io/r/base/browser.html) before simulating.
  Default `FALSE`.

- verbose:

  Logical. If `TRUE`, print the resolved `eta`/ `nu`/`beta` parameters.
  Default `FALSE`.

## Value

A `data.table` of simulated event history data with columns `id`,
`time`, `delta`, the baseline covariates, and one column per
non-terminal process.

## Details

Unlike
[`sim.generic`](https://github.com/miclukacova/simevent/reference/sim.generic.md),
which takes user-specified effects directly, `sim.from.data` is meant to
be fed parameters estimated from real data, so that the simulated data
mimics an observed dataset's distribution (optionally under an
intervention via `alpha.intervention`/`baseline.intervention`). See
[`sim_graph_from_fits`](https://github.com/miclukacova/simevent/reference/sim_graph_from_fits.md)
for a more convenient way to do this directly from `coxph` fits and the
data they were fit to, without hand-building `sim.parameters`.
