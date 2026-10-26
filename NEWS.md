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

- Added `sim_model()`, `sim_covariate()`, `sim_derived()`, `sim_mark()`,
  `sim_process()`, `sim_effect()`, `sim_events()` and `sim_model_from_fits()`.

# simevent 0.1.1

## Bug fixes

- Fixed some tests

## Improvements

- changed `simEventCox()` to take `list_old_vars` as input

## New features

- Added `simStatinData()`
