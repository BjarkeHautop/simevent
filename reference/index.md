# Package index

## Package overview

Overview of the simevent package.

- [`simevent`](https://github.com/miclukacova/simevent/reference/simevent-package.md)
  [`simevent-package`](https://github.com/miclukacova/simevent/reference/simevent-package.md)
  : simevent: Simulation and Analysis of Event History Data

## Graph-based simulation

Build a simulation spec as a graph of covariates, event processes, and
effects between them, and simulate event history data from it.

- [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  :

  Build a Simulation Graph for
  [`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)

- [`sim_covariate()`](https://github.com/miclukacova/simevent/reference/sim_covariate.md)
  :

  Define a Baseline Covariate for
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

- [`sim_derived()`](https://github.com/miclukacova/simevent/reference/sim_derived.md)
  :

  Define a Derived Covariate for
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

- [`sim_process()`](https://github.com/miclukacova/simevent/reference/sim_process.md)
  :

  Define an Event Process for
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

- [`sim_effect()`](https://github.com/miclukacova/simevent/reference/sim_effect.md)
  :

  Define an Effect for
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

- [`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)
  :

  Simulate Event History Data from a
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)

- [`sim_graph_from_fits()`](https://github.com/miclukacova/simevent/reference/sim_graph_from_fits.md)
  :

  Build a
  [`sim_graph()`](https://github.com/miclukacova/simevent/reference/sim_graph.md)
  from Fitted Cox Models

## Treating graph-based simulated data

Functions for formatting, plotting, and summarising data simulated with
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md).

- [`interval_format_data()`](https://github.com/miclukacova/simevent/reference/interval_format_data.md)
  : Transform Graph-Based Event Data into Interval Format for Classical
  Inference
- [`plot_event_data()`](https://github.com/miclukacova/simevent/reference/plot_event_data.md)
  : Plot Graph-Based Simulated Event History Data
- [`event_risk()`](https://github.com/miclukacova/simevent/reference/event_risk.md)
  : Risk of, or Time Lost to, an Event by a Time Horizon

## Core simulation (old)

Functions for simulating event history data, built on the old
simEventData/simEventTV engine. Will be removed in the future.

- [`simEventData()`](https://github.com/miclukacova/simevent/reference/simEventData.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types
- [`simEventTV()`](https://github.com/miclukacova/simevent/reference/simEventTV.md)
  : Simulate Event Data with Time-Varying Effects
- [`simEventDataTdPhi()`](https://github.com/miclukacova/simevent/reference/simEventDataTdPhi.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types and
  time dependent effects
- [`sim.generic()`](https://github.com/miclukacova/simevent/reference/sim.generic.md)
  : Simulate Event History Data from a Generic Process Specification

## Preset wrappers (old)

Ready-made wrappers for common settings, each hard-coding a fixed
baseline/process/effect specification on top of simEventData(). Will be
removed in the future.

- [`simSurvData()`](https://github.com/miclukacova/simevent/reference/simSurvData.md)
  : Simulate Survival Data with Censoring and Event Times
- [`simCRdata()`](https://github.com/miclukacova/simevent/reference/simCRdata.md)
  : Simulate Competing Risks Data
- [`simDisease()`](https://github.com/miclukacova/simevent/reference/simDisease.md)
  : Simulate Data in a Disease Setting
- [`simTreatment()`](https://github.com/miclukacova/simevent/reference/simTreatment.md)
  : Simulate Event History Data with Treatment and Time-Dependent
  Covariate
- [`simDropIn()`](https://github.com/miclukacova/simevent/reference/simDropIn.md)
  : Simulate Event Data from a "Drop In" Setting
- [`simStatinData()`](https://github.com/miclukacova/simevent/reference/simStatinData.md)
  : Simulate Data in a Statin Setting

## Treating simulated data (old)

Functions for formatting and plotting event history data simulated with
the old engine. Will be removed in the future.

- [`IntFormatData()`](https://github.com/miclukacova/simevent/reference/IntFormatData.md)
  : Transform Event Data into Interval Format for Classical Inference
- [`plotEventData()`](https://github.com/miclukacova/simevent/reference/plotEventData.md)
  : Plot Simulated Event History Data

## Simulating from fitted models (old)

Functions for simulating new data from models fitted to observed data,
built on the old engine. Will be removed in the future.

- [`simEventCox()`](https://github.com/miclukacova/simevent/reference/simEventCox.md)
  : Simulate Event History Data Based on Cox Models
- [`simEventObj()`](https://github.com/miclukacova/simevent/reference/simEventObj.md)
  : Simulate Survival and Competing Risk Data Based on a General Model
- [`sim.from.data()`](https://github.com/miclukacova/simevent/reference/sim.from.data.md)
  : Simulate Event History Data from Parameters Fitted to Observed Data

## Interventions (old)

Functions for performing interventions on the shape parameter of a
process, and estimating their effect. Will be removed in the future.

- [`alphaSim()`](https://github.com/miclukacova/simevent/reference/alphaSim.md)
  : Simulation and Estimation with Modified Shape Parameter
- [`intEffectAlpha()`](https://github.com/miclukacova/simevent/reference/intEffectAlpha.md)
  : Estimate Effect of Intervention: Modifying Eta Parameter of Process
