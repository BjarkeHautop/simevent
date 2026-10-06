# Changelog

## simevent (development version)

### Deprecations

- The old engine and everything built on it is deprecated in favour of
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  and
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md).
  Each of the following now warns via
  [`lifecycle::deprecate_warn()`](https://lifecycle.r-lib.org/reference/deprecate_soft.html)
  and will be removed in a future release:
  [`simEventData()`](https://github.com/BjarkeHautop/simevent/reference/simEventData.md),
  [`simEventDataTdPhi()`](https://github.com/BjarkeHautop/simevent/reference/simEventDataTdPhi.md),
  [`simEventTV()`](https://github.com/BjarkeHautop/simevent/reference/simEventTV.md),
  [`simSurvData()`](https://github.com/BjarkeHautop/simevent/reference/simSurvData.md),
  [`simCRdata()`](https://github.com/BjarkeHautop/simevent/reference/simCRdata.md),
  [`simDisease()`](https://github.com/BjarkeHautop/simevent/reference/simDisease.md),
  [`simTreatment()`](https://github.com/BjarkeHautop/simevent/reference/simTreatment.md),
  [`simDropIn()`](https://github.com/BjarkeHautop/simevent/reference/simDropIn.md),
  [`simStatinData()`](https://github.com/BjarkeHautop/simevent/reference/simStatinData.md),
  [`sim.generic()`](https://github.com/BjarkeHautop/simevent/reference/sim.generic.md)
  (use
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)),
  [`simEventCox()`](https://github.com/BjarkeHautop/simevent/reference/simEventCox.md),
  [`simEventObj()`](https://github.com/BjarkeHautop/simevent/reference/simEventObj.md),
  [`sim.from.data()`](https://github.com/BjarkeHautop/simevent/reference/sim.from.data.md)
  (use
  [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md)),
  [`alphaSim()`](https://github.com/BjarkeHautop/simevent/reference/alphaSim.md),
  [`intEffectAlpha()`](https://github.com/BjarkeHautop/simevent/reference/intEffectAlpha.md)
  (use `sim_events(intervene = )` with
  [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)),
  [`IntFormatData()`](https://github.com/BjarkeHautop/simevent/reference/IntFormatData.md)
  (use
  [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md))
  and
  [`plotEventData()`](https://github.com/BjarkeHautop/simevent/reference/plotEventData.md)
  (use
  [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)).

### New features

- [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
  gains a `seed` argument for reproducible simulation without touching
  the global RNG stream.
- [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  now rejects: reserved node names (`id`, `time`, `event`, `max_cens`,
  `none`, `t`, `last_time`), models without a terminal process,
  duplicate effects, effects from censoring/terminal processes, and
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)
  generators whose arguments don’t name an earlier covariate.
- Added a [`summary()`](https://rdrr.io/r/base/summary.html) method for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  objects.
- Added
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md),
  [`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md),
  [`sim_marker()`](https://github.com/BjarkeHautop/simevent/reference/sim_marker.md),
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md),
  [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md),
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
  and
  [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md).
- Added
  [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)
  for summarising risk / time lost from
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
  output,
  [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md)
  and
  [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md).

## simevent 0.1.1

CRAN release: 2026-04-24

### Bug fixes

- Fixed some tests

### Improvements

- changed sim_event_cox to take list_old_vars as input

### New features

- Added `sim_statin_data()`
