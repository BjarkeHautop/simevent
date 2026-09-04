# Package index

## Package overview

Overview of the simevent package.

- [`simevent`](https://github.com/miclukacova/simevent/reference/simevent-package.md)
  [`simevent-package`](https://github.com/miclukacova/simevent/reference/simevent-package.md)
  : simevent: Simulation and Analysis of Event History Data

## Core simulation

Functions for simulating event history data, built on the
general-purpose simEventData/simEventTV engine, plus ready-made wrappers
for common settings.

- [`simEventData()`](https://github.com/miclukacova/simevent/reference/simEventData.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types
- [`simEventTV()`](https://github.com/miclukacova/simevent/reference/simEventTV.md)
  : Simulate Event Data with Time-Varying Effects
- [`simEventDataTdPhi()`](https://github.com/miclukacova/simevent/reference/simEventDataTdPhi.md)
  : Simulate Continuous Time-to-Event Data with Multiple Event Types and
  time dependent effects
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

## Treating simulated data

Functions for formatting and plotting simulated event history data.

- [`IntFormatData()`](https://github.com/miclukacova/simevent/reference/IntFormatData.md)
  : Transform Event Data into Interval Format for Classical Inference
- [`plotEventData()`](https://github.com/miclukacova/simevent/reference/plotEventData.md)
  : Plot Simulated Event History Data

## Simulating from fitted models

Functions for simulating new data from models fitted to observed data.

- [`simEventCox()`](https://github.com/miclukacova/simevent/reference/simEventCox.md)
  : Simulate Event History Data Based on Cox Models
- [`simEventObj()`](https://github.com/miclukacova/simevent/reference/simEventObj.md)
  : Simulate Survival and Competing Risk Data Based on a General Model

## Interventions

Functions for performing interventions on the shape parameter of a
process, and estimating their effect.

- [`alphaSim()`](https://github.com/miclukacova/simevent/reference/alphaSim.md)
  : Simulation and Estimation with Modified Shape Parameter
- [`intEffectAlpha()`](https://github.com/miclukacova/simevent/reference/intEffectAlpha.md)
  : Estimate Effect of Intervention: Modifying Eta Parameter of Process
