# simevent (development version)

## Deprecations

- The old engine and everything built on it is deprecated in favour of the
  graph-based API (`sim_graph()`, `sim_event_graph()`, ...). Each of the
  following now warns via `lifecycle::deprecate_warn()` and will be removed in a
  future release: `simEventData()`, `simEventDataTdPhi()`, `simEventTV()`,
  `simSurvData()`, `simCRdata()`, `simDisease()`, `simTreatment()`,
  `simDropIn()`, `simStatinData()`, `sim.generic()` (use `sim_graph()`),
  `simEventCox()`, `simEventObj()`, `sim.from.data()` (use
  `sim_graph_from_fits()`), `alphaSim()`, `intEffectAlpha()` (use
  `sim_event_graph(intervene = )` with `event_risk()`), `IntFormatData()` (use
  `interval_format_data()`) and `plotEventData()` (use `plot_event_data()`).

## New features

- Added the graph-based API: `sim_graph()`, `sim_covariate()`, `sim_derived()`,
  `sim_process()`, `sim_effect()`, `sim_event_graph()` and
  `sim_graph_from_fits()`.
- Added `event_risk()` for summarising risk / time lost from `sim_event_graph()`
  output, `interval_format_data()` and `plot_event_data()`.

# simevent 0.1.1

## Bug fixes

- Fixed some tests

## Improvements

- changed sim_event_cox to take list_old_vars as input

## New features

- Added `sim_statin_data()`
