# Changelog

## simevent (development version)

### Breaking changes

- Removed the old engine and everything built on it in favour of
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  and
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md):
  `simEventData()`, `simEventDataTdPhi()`, `simEventTV()`,
  `simSurvData()`, `simCRdata()`, `simDisease()`, `simTreatment()`,
  `simDropIn()`, `simStatinData()`, `sim.generic()` (use
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)),
  `simEventCox()`, `simEventObj()`, `sim.from.data()` (use
  [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md)),
  `alphaSim()`, `intEffectAlpha()` (use `sim_events(intervene = )` with
  [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)),
  `IntFormatData()` (use
  [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md))
  and `plotEventData()` (use
  [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)).

### New features

- Added
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md),
  [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md),
  [`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md),
  [`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md),
  [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md),
  [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md),
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
  and
  [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md).

## simevent 0.1.1

CRAN release: 2026-04-24

### Bug fixes

- Fixed some tests

### Improvements

- changed `simEventCox()` to take `list_old_vars` as input

### New features

- Added `simStatinData()`
