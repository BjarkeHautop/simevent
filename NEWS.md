# simevent (development version)

## Deprecations

- The old engine and everything built on it is deprecated in favour of
  `sim_model()` and `sim_events()`. Each of the following now warns via
  `lifecycle::deprecate_warn()` and will be removed in a future release:
  `simEventData()`, `simEventDataTdPhi()`, `simEventTV()`, `simSurvData()`,
  `simCRdata()`, `simDisease()`, `simTreatment()`, `simDropIn()`,
  `simStatinData()`, `sim.generic()` (use `sim_model()`), `simEventCox()`,
  `simEventObj()`, `sim.from.data()` (use `sim_model_from_fits()`),
  `alphaSim()`, `intEffectAlpha()` (use `sim_events(intervene = )` with
  `event_risk()`), `IntFormatData()` (use `interval_format_data()`) and
  `plotEventData()` (use `plot_event_data()`).

## New features

- `sim_events()` gains a `seed` argument for reproducible simulation without
  touching the global RNG stream.
- `sim_model()` now rejects: reserved node names (`id`, `time`, `event`,
  `max_cens`, `none`, `t`, `last_time`, `nth_time`), models without a terminal
  process, duplicate effects, effects from censoring/terminal processes, and
  `sim_covariate()` generators whose arguments don't name an earlier covariate.
- Added a `summary()` method for `sim_model()` objects.
- Added `sim_model()`, `sim_covariate()`, `sim_derived()`, `sim_process()`,
  `sim_effect()`, `sim_events()` and `sim_model_from_fits()`.
- Added `event_risk()` for summarising risk / time lost from `sim_events()`
  output, `interval_format_data()` and `plot_event_data()`.

# simevent 0.1.1

## Bug fixes

- Fixed some tests

## Improvements

- changed sim_event_cox to take list_old_vars as input

## New features

- Added `sim_statin_data()`
