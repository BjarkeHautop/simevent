# Build a `sim_graph()` from Fitted Cox Models

`sim_graph_from_fits` builds a
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
automatically from a set of fitted
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)
models (one per process) and the data they were fit to, so simulated
data mimics an observed dataset's distribution.

## Usage

``` r
sim_graph_from_fits(fits, data, types, limits = list())
```

## Arguments

- fits:

  Named list of
  [`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)
  fits, one per process, named after the process. Every process
  referenced as a covariate in any fit's formula (a cross-process
  effect) must also have its own entry here.

- data:

  The `data.frame` the fits were estimated from; must contain every
  covariate referenced in `fits` that isn't itself one of `fits`'
  processes.

- types:

  Named character vector giving each process's
  [`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md)
  `type` (`"censoring"`, `"terminal"`, or `"transient"`), with the same
  names as `fits`.

- limits:

  Named list giving `limit` for any `"transient"` process not using the
  default (`limit = Inf`).

## Value

A
[`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md),
ready for
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md).

## Details

Baseline covariates are regenerated from `data`'s own columns: numeric
columns as Normal(mean, sd) (or Bernoulli(mean) if the column is 0/1
valued), and factor columns as a categorical draw from their observed
proportions, with one
[`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
dummy per non-reference level, matching how
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)'s
default treatment contrasts name coefficients (`"<variable><level>"`).
Categorical covariates must therefore be factor columns in `data`,
referenced directly in each
[`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) formula (not
wrapped in [`factor()`](https://rdrr.io/r/base/factor.html) there).

Each process's Weibull `eta`/`nu` is approximated from its
[`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) fit's baseline
cumulative hazard.

A [`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) term that
names another process in `fits`/`types` (rather than a column of `data`)
is a cross-process effect – e.g. `coxph(Surv(...) ~ L0 + relapse)`,
where `relapse` is itself one of the processes being modeled – and is
wired as a
[`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)
from that process directly, not regenerated as a (meaningless, since its
true value evolves over follow-up rather than being fixed at baseline)
covariate. Note that such a term must itself have been fit as a properly
time-varying covariate (e.g. via
[`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) on tstart-tstop
data built with
[`IntFormatData()`](https://github.com/miclukacova/simevent/reference/IntFormatData.md))
for its coefficient to be a valid estimate in the first place;
`sim_graph_from_fits()` only wires whatever coefficient `fits` already
contains, it does not check how that fit was estimated.

## See also

[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md),
[`sim.from.data()`](https://github.com/miclukacova/simevent/reference/sim.from.data.md)

## Examples

``` r
library(survival)

# Some "observed" data, from a 3-cause competing-risks sim_graph():
set.seed(1405)
observed_graph <- sim_graph(
  L0 = sim_covariate(function(N) runif(N)),
  A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  cause1 = sim_process("terminal", eta = 0.1, nu = 1.1),
  cause2 = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect("L0", "censoring", 0.5),
    sim_effect("A0", "censoring", -1),
    sim_effect("L0", "cause1", -0.5),
    sim_effect("A0", "cause1", 0.5),
    sim_effect("A0", "cause2", 0.5)
  )
)
observed_data <- sim_event_graph(observed_graph, n = 1000)

# Refit each process from that "observed" data, then rebuild a sim_graph()
# from the fits, as if observed_data came from an outside source and
# observed_graph were unknown:
fits <- list(
  censoring = coxph(Surv(time, delta == 0) ~ L0 + A0, data = observed_data),
  cause1 = coxph(Surv(time, delta == 1) ~ L0 + A0, data = observed_data),
  cause2 = coxph(Surv(time, delta == 2) ~ L0 + A0, data = observed_data)
)
types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")

graph <- sim_graph_from_fits(fits, observed_data, types)
new_data <- sim_event_graph(graph, n = 1000)
head(new_data)
#> Key: <id>
#>       id     time delta        L0    A0
#>    <int>    <num> <int>     <num> <int>
#> 1:     1 4.549795     0 1.0532139     1
#> 2:     2 3.550653     0 0.5385115     0
#> 3:     3 1.797275     1 0.8235271     1
#> 4:     4 1.095931     2 0.7444320     0
#> 5:     5 8.083563     0 0.4030154     0
#> 6:     6 1.474290     0 0.4556481     1

# Event-type distribution should be comparable between the observed and
# newly simulated data:
rbind(
  observed = prop.table(table(observed_data$delta)),
  simulated = prop.table(table(new_data$delta))
)
#>               0     1     2
#> observed  0.294 0.316 0.390
#> simulated 0.280 0.327 0.393
```
