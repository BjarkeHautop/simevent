# simevent (development version)

## Breaking changes

- Removed the old engine and everything built on it in favour of `sim_model()`
  and `sim_events()`: `simEventData()`, `simEventDataTdPhi()`, `simEventTV()`,
  `simSurvData()`, `simCRdata()`, `simDisease()`, `simTreatment()`,
  `simDropIn()`, `simStatinData()`, `sim.generic()` (use `sim_model()`),
  `simEventCox()`, `simEventObj()`, `sim.from.data()` (use
  `sim_model_from_fits()`), `alphaSim()`, `intEffectAlpha()` (use
  `sim_events(intervene = )` with `event_risk()`), `IntFormatData()` (use
  `interval_format_data()`) and `plotEventData()` (use `plot_event_data()`).

## New features

- Added `sim_model()`, `sim_covariate()`, `sim_derived()`, `sim_mark()`,
  `sim_process()`, `sim_effect()`, `event_time()`, `sim_events()`,
  `sim_model_from_fits()`, `event_risk()`, `interval_format_data()` and
  `plot_event_data()`.

# simevent 0.1.1

## Bug fixes

- Fixed some tests

## Improvements

- changed `simEventCox()` to take `list_old_vars` as input

## New features

- Added `simStatinData()`
