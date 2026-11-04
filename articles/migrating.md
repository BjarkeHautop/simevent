# Migrating from simevent 0.1.1

``` r

library(simevent)
```

## Introduction

simevent 0.1.1’s functions (`simEventData()`, the preset wrappers such
as `simSurvData()`, `sim.generic()`, `sim.from.data()`, `alphaSim()`, …)
have been removed in favour of the
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)/[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
API. This vignette shows how to translate code using the old functions.
See
[`vignette("sim-events")`](https://github.com/BjarkeHautop/simevent/articles/sim-events.md)
for an introduction to the new API itself.

| simevent 0.1.1 | Replacement |
|----|----|
| `simEventData()`, `simSurvData()`, `simCRdata()`, `simDisease()`, `simTreatment()`, `simStatinData()`, `sim.generic()`, … | [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md) + [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md) |
| `alphaSim()`, `intEffectAlpha()` | `sim_events(intervene = )` + [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md) |
| `sim.from.data()` | [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md) |
| `IntFormatData()` | [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md) |
| `plotEventData()` | [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md) |

The old functions coded events as integers in `Delta`;
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
returns the process name in `event`, and `id`/`time` in place of
`ID`/`Time`.

## Translating the Preset Wrappers

### `simSurvData()`

`simSurvData()`’s default (`beta = NULL`, i.e. no covariate effects) is
two terminal processes, censoring and death, both with `eta = 0.1`,
`nu = 1.1`. The old call

``` r

simSurvData(200)
```

becomes

``` r

model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1)
)
model_data <- sim_events(model, n = 200)
```

### `simCRdata()`

`simCRdata()` adds a third terminal process (a second competing cause):

``` r

beta <- matrix(c(0.5, -1, -0.5, 0.5, 0, 0.5), ncol = 3, nrow = 2)
simCRdata(N = 200, beta = beta)
```

becomes

``` r

model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  cause1 = sim_process("terminal", eta = 0.1, nu = 1.1),
  cause2 = sim_process("terminal", eta = 0.1, nu = 1.1),
  effects = list(
    sim_effect(censoring ~ L0 + A0, coef = c(0.5, -1)),
    sim_effect(cause1 ~ L0 + A0, coef = c(-0.5, 0.5)),
    sim_effect(cause2 ~ A0, coef = 0.5)
  )
)
model_data <- sim_events(model, n = 200)
```

### `simDisease()`

`simDisease()` has a censoring process, a terminal death process, and a
covariate process `L` that can happen at most once and can itself affect
death; a `"transient"` process with `limit = 1`:

``` r

simDisease(
  N = 5000,
  cens = 1,
  eta = c(0.1, 0.3, 0.1),
  nu = c(1.1, 1.3, 1.1),
  beta_L0_L = 1,
  beta_A0_L = -1.1,
  beta_L_D = 1,
  beta_L0_D = 0
)
```

becomes

``` r

model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.3, nu = 1.3),
  L = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  effects = list(
    sim_effect(L ~ L0, 1),
    sim_effect(L ~ A0, -1.1),
    sim_effect(death ~ L, 1)
  )
)
model_data <- sim_events(model, n = 5000)
```

### `simTreatment()`

`simTreatment()` (with `op = 1`, the default) adds a second
`"transient"` process, treatment (`A`), which can itself affect and be
affected by the covariate process `L`. `simTreatment()` doesn’t declare
its own `A0`, so its translation skips it too:
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
has no default covariates.

``` r

simTreatment(
  N = 5000,
  beta_L_A = 1,
  beta_L_D = 1,
  beta_A_D = -1,
  beta_A_L = -0.5,
  beta_L0_A = 1,
  eta = rep(0.1, 4),
  nu = rep(1.1, 4),
  cens = 1,
  op = 1
)
```

becomes

``` r

model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  A = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  L = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  effects = list(
    sim_effect(death ~ L0, 1),
    sim_effect(A ~ L0, 1),
    sim_effect(L ~ L0, 1),
    sim_effect(death ~ A, -1),
    sim_effect(L ~ A, -0.5),
    sim_effect(death ~ L, 1),
    sim_effect(A ~ L, 1)
  )
)
model_data <- sim_events(model, n = 5000)
```

### `simStatinData()`

`simStatinData()` mainly demonstrates non-default baseline covariate
generators.
[`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)
reproduces this directly, with no forced covariate names to work around:

``` r

set.seed(1405)
model <- sim_model(
  L0 = sim_covariate(function(N) rbinom(N, 1, 0.4)),
  A0 = sim_covariate(function(N, L0) pmin(rexp(N, 0.3) + 70, 100)),
  censoring = sim_process("censoring", eta = 0.025, nu = 1.1),
  death = sim_process("terminal", eta = 0.025, nu = 1.1)
)
model_data <- sim_events(model, n = 200)
summary(model_data$A0)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   70.00   70.82   71.96   73.14   74.18   85.01
```

## `sim.generic()`

`sim.generic()`’s `alpha.intervention`/`baseline.intervention` pair is
replaced by
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)’s
single `intervene` list: give a process name to scale its `eta`, or a
covariate name to fix it to a constant, as in
`sim_events(model, n, intervene = list(death = 0.2, L0 = 1))`.

## `alphaSim()` and `intEffectAlpha()`

`alphaSim()` and `intEffectAlpha()` simulate one of the preset settings
with the `eta` of one process multiplied by `alpha`, and summarise the
result as the proportion of individuals experiencing death and the
intervened process by time \tau (or the years lost to them before \tau).
Take the `"Disease"` setting with `alpha = 0.5`:

``` r

alphaSim(
  N = 5000,
  eta = rep(0.1, 3),
  nu = rep(1.1, 3),
  alpha = 0.5,
  tau = 5,
  setting = "Disease"
)
```

becomes a
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
of the setting, simulated with `intervene = list(L = 0.5)` and
summarised with
[`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md).
`alphaSim()` switches censoring off by default, so pass `cens = 0`:

``` r

model <- sim_model(
  L0 = sim_covariate(function(N) runif(N)),
  A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1),
  L = sim_process("transient", eta = 0.1, nu = 1.1, limit = 1),
  effects = list(
    sim_effect(death ~ L0, 1),
    sim_effect(L ~ L0, 1),
    sim_effect(death ~ L, 1)
  )
)
set.seed(1405)
intervened <- sim_events(model, n = 5000, cens = 0, intervene = list(L = 0.5))
event_risk(intervened, model, c("death", "L"), tau = 5)
#>    process   risk
#>     <char>  <num>
#> 1:   death 0.7012
#> 2:       L 0.2538
```

The remaining arguments map as follows:

- `years_lost = TRUE` is `event_risk(type = "time_lost")`.
- `a0` (summarise only individuals with `A0 == a0`) is `by = "A0"`,
  which summarises every group at once.
- `intEffectAlpha()`’s `plot = TRUE` is
  [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)
  on the intervened data.

See “Estimating Intervention Effects” in
[`vignette("sim-events")`](https://github.com/BjarkeHautop/simevent/articles/sim-events.md)
for comparing against the run without intervention.

## `sim.from.data()`

[`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md)
builds a
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
from a list of fitted
[`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) models (one per
process) and the data they were fit to. Unlike `sim.from.data()`,
there’s no `sim.parameters` list to build:

- The `baseline.summary` computed by hand from
  [`mean()`](https://rdrr.io/r/base/mean.html)/[`sd()`](https://rdrr.io/r/stats/sd.html)/[`min()`](https://rdrr.io/r/base/Extremes.html)/[`max()`](https://rdrr.io/r/base/Extremes.html)
  is gone: baseline covariates are resampled as whole rows of the data,
  keeping each covariate’s distribution and the relationships between
  them.
- `"(region==2)"`-style expressions for categorical covariates are
  replaced by factor columns used directly in the
  [`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html) formula;
  dummies are named to match
  [`coxph()`](https://rdrr.io/pkg/survival/man/coxph.html)’s own
  coefficient names (`"<variable><level>"`).

See “Building a
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
from Fitted Cox Models” in
[`vignette("sim-events")`](https://github.com/BjarkeHautop/simevent/articles/sim-events.md)
for a worked example.
