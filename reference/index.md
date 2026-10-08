# Package index

## Package overview

Overview of the simevent package.

- [`simevent`](https://github.com/BjarkeHautop/simevent/reference/simevent-package.md)
  [`simevent-package`](https://github.com/BjarkeHautop/simevent/reference/simevent-package.md)
  : simevent: Simulation and Analysis of Event History Data

## Simulation

Build a simulation model of covariates, event processes, and effects
between them, and simulate event history data from it.

- [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  :

  Build a Simulation Model for
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)

- [`sim_covariate()`](https://github.com/BjarkeHautop/simevent/reference/sim_covariate.md)
  :

  Define a Baseline Covariate for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_derived()`](https://github.com/BjarkeHautop/simevent/reference/sim_derived.md)
  :

  Define a Derived Covariate for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_mark()`](https://github.com/BjarkeHautop/simevent/reference/sim_mark.md)
  :

  Define a Time-Varying Covariate for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_process()`](https://github.com/BjarkeHautop/simevent/reference/sim_process.md)
  :

  Define an Event Process for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_effect()`](https://github.com/BjarkeHautop/simevent/reference/sim_effect.md)
  :

  Define an Effect for
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
  :

  Simulate Event History Data from a
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

- [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md)
  :

  Build a
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
  from Fitted Cox Models

- [`summary(`*`<sim_model>`*`)`](https://github.com/BjarkeHautop/simevent/reference/summary.sim_model.md)
  [`print(`*`<summary.sim_model>`*`)`](https://github.com/BjarkeHautop/simevent/reference/summary.sim_model.md)
  :

  Summarise a
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

## Treating simulated data

Functions for formatting, plotting, and summarising data simulated with
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md).

- [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md)
  : Convert Simulated Event Data to Start-Stop Format
- [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)
  : Plot Simulated Event History Data
- [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)
  : Risk of, or Time Lost to, an Event by a Time Horizon

## Core simulation (old)

Functions for simulating event history data, built on the old
simEventData/simEventTV engine. Will be removed in the future.

- [`simEventData()`](https://github.com/BjarkeHautop/simevent/reference/simEventData.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types
- [`simEventTV()`](https://github.com/BjarkeHautop/simevent/reference/simEventTV.md)
  : Simulate Event Data with Time-Varying Effects
- [`simEventDataTdPhi()`](https://github.com/BjarkeHautop/simevent/reference/simEventDataTdPhi.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types and
  time dependent effects
- [`sim.generic()`](https://github.com/BjarkeHautop/simevent/reference/sim.generic.md)
  : Simulate Event History Data from a Generic Process Specification

## Preset wrappers (old)

Ready-made wrappers for common settings, each hard-coding a fixed
baseline/process/effect specification on top of simEventData(). Will be
removed in the future.

- [`simSurvData()`](https://github.com/BjarkeHautop/simevent/reference/simSurvData.md)
  : Simulate Survival Data with Censoring and Event Times
- [`simCRdata()`](https://github.com/BjarkeHautop/simevent/reference/simCRdata.md)
  : Simulate Competing Risks Data
- [`simDisease()`](https://github.com/BjarkeHautop/simevent/reference/simDisease.md)
  : Simulate Data in a Disease Setting
- [`simTreatment()`](https://github.com/BjarkeHautop/simevent/reference/simTreatment.md)
  : Simulate Event History Data with Treatment and Time-Dependent
  Covariate
- [`simDropIn()`](https://github.com/BjarkeHautop/simevent/reference/simDropIn.md)
  : Simulate Event Data from a "Drop In" Setting
- [`simStatinData()`](https://github.com/BjarkeHautop/simevent/reference/simStatinData.md)
  : Simulate Data in a Statin Setting

## Treating simulated data (old)

Functions for formatting and plotting event history data simulated with
the old engine. Will be removed in the future.

- [`IntFormatData()`](https://github.com/BjarkeHautop/simevent/reference/IntFormatData.md)
  : Transform Event Data into Interval Format for Classical Inference
- [`plotEventData()`](https://github.com/BjarkeHautop/simevent/reference/plotEventData.md)
  : Plot Simulated Event History Data

## Simulating from fitted models (old)

Functions for simulating new data from models fitted to observed data,
built on the old engine. Will be removed in the future.

- [`simEventCox()`](https://github.com/BjarkeHautop/simevent/reference/simEventCox.md)
  : Simulate Event History Data Based on Cox Models
- [`simEventObj()`](https://github.com/BjarkeHautop/simevent/reference/simEventObj.md)
  : Simulate Survival and Competing Risk Data Based on a General Model
- [`sim.from.data()`](https://github.com/BjarkeHautop/simevent/reference/sim.from.data.md)
  : Simulate Event History Data from Parameters Fitted to Observed Data

## Interventions (old)

Functions for performing interventions on the shape parameter of a
process, and estimating their effect. Will be removed in the future.

- [`alphaSim()`](https://github.com/BjarkeHautop/simevent/reference/alphaSim.md)
  : Simulation and Estimation with Modified Shape Parameter
- [`intEffectAlpha()`](https://github.com/BjarkeHautop/simevent/reference/intEffectAlpha.md)
  : Estimate Effect of Intervention: Modifying Eta Parameter of Process
