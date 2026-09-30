# Build a `sim_graph()` from Fitted Cox Models

Builds a
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md)
from one fitted
[`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) model
per process, so simulated data resembles the data they were fit to.

## Usage

``` r
sim_graph_from_fits(fits, data, types, limits = list())
```

## Arguments

- fits:

  Named list of
  [`survival::coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)
  fits, one per process.

- data:

  The `data.frame` the fits were estimated from.

- types:

  Named character vector giving each process's
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  `type` (`"censoring"`, `"terminal"`, or `"transient"`), with the same
  names as `fits`.

- limits:

  Named list giving `limit` for any `"transient"` process not using the
  default (`limit = Inf`).

## Value

A
[`sim_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_graph.md),
ready for
[`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md).

## Details

Covariates are regenerated from `data`: numeric columns as Normal (or
Bernoulli if 0/1), factor columns from their observed proportions.
Categorical covariates must be factor columns, used as-is in the
[`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) formulas (not
wrapped in [`factor()`](https://rdrr.io/r/base/factor.html)). Each
process's Weibull parameters are fit to its baseline cumulative hazard.

A formula term naming another process (e.g. `relapse` in
`~ L0 + relapse`) becomes a
[`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)
from that process. Its coefficient is only valid if that fit treated it
as time-varying (e.g. using
[`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md)).

## See also

[`sim_event_graph()`](https://github.com/BjarkeHautop/simevent/reference/sim_event_graph.md)

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
  censoring = coxph(
    Surv(time, event == "censoring") ~ L0 + A0,
    data = observed_data
  ),
  cause1 = coxph(Surv(time, event == "cause1") ~ L0 + A0, data = observed_data),
  cause2 = coxph(Surv(time, event == "cause2") ~ L0 + A0, data = observed_data)
)
types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")

graph <- sim_graph_from_fits(fits, observed_data, types)
new_data <- sim_event_graph(graph, n = 1000)
head(new_data)
#> Key: <id>
#>       id     time     event        L0    A0
#>    <int>    <num>    <fctr>     <num> <int>
#> 1:     1 4.549795 censoring 1.0532139     1
#> 2:     2 3.550653 censoring 0.5385115     0
#> 3:     3 1.797275    cause1 0.8235271     1
#> 4:     4 1.095931    cause2 0.7444320     0
#> 5:     5 8.083563 censoring 0.4030154     0
#> 6:     6 1.474290 censoring 0.4556481     1

# Event-type distribution should be comparable between the observed and
# newly simulated data:
rbind(
  observed = prop.table(table(observed_data$event)),
  simulated = prop.table(table(new_data$event))
)
#>           censoring cause1 cause2
#> observed      0.294  0.316  0.390
#> simulated     0.280  0.327  0.393
```
