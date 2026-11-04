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
  [`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)

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

- [`event_time()`](https://github.com/BjarkeHautop/simevent/reference/event_time.md)
  : Time of an Earlier Event

- [`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md)
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

- [`update(`*`<sim_model>`*`)`](https://github.com/BjarkeHautop/simevent/reference/update.sim_model.md)
  :

  Update a
  [`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)

## Treating simulated data

Functions for formatting, plotting, and summarising data simulated with
[`simulate_events()`](https://github.com/BjarkeHautop/simevent/reference/simulate_events.md).

- [`format_interval_data()`](https://github.com/BjarkeHautop/simevent/reference/format_interval_data.md)
  : Convert Simulated Event Data to Start-Stop Format
- [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)
  : Plot Simulated Event History Data
- [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md)
  : Risk of, or Time Lost to, an Event by a Time Horizon
