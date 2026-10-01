# simevent

The `simevent` package provides tools for simulating and analyzing
complex continuous-time health care data. The simulated data includes
variables that can be interpreted as treatment decisions, disease
progression, and health factors.

## Installation

You can install the stable version of simevent from CRAN with:

``` r

install.packages("simevent")
```

or the development version of simevent from GitHub using pak:

``` r

pak::pak("BjarkeHautop/simevent")
```

## Usage

``` r

library(simevent)
```

The package builds event history data from a *model*: baseline
covariates, event processes (censoring, terminal, or transient, with
Weibull or user-given intensities), and the Cox-type effects between
them.
[`sim_model()`](https://github.com/BjarkeHautop/simevent/reference/sim_model.md)
defines the model and
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
simulates from it. On top of this, the package provides:

- [`sim_model_from_fits()`](https://github.com/BjarkeHautop/simevent/reference/sim_model_from_fits.md)
  for building a model from `coxph()` fits to observed data, to simulate
  new data resembling it.
- [`interval_format_data()`](https://github.com/BjarkeHautop/simevent/reference/interval_format_data.md)
  and
  [`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)
  for reformatting and plotting simulated data.
- The `intervene` argument of
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md),
  together with
  [`event_risk()`](https://github.com/BjarkeHautop/simevent/reference/event_risk.md),
  for simulating and evaluating interventions on processes and
  covariates.

A minimal example, simulating survival data for 100 individuals and
plotting the event histories:

``` r

model <- sim_model(
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1)
)
data <- sim_events(model, n = 100)
plot_event_data(data, title = "Survival Data")
```

![](reference/figures/README-quick-example-1.png)

For a full walkthrough of the simulation framework and all of the
functions above, see
[`vignette("sim-events")`](https://github.com/BjarkeHautop/simevent/articles/sim-events.md).

## Contributing

All contributions are welcome!
