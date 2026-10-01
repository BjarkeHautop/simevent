# Plot Simulated Event History Data

One horizontal timeline per individual, with events marked by type.

## Usage

``` r
plot_event_data(data, title = "Event Data")
```

## Arguments

- data:

  Output of
  [`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md).

- title:

  Character. Plot title. Default `"Event Data"`.

## Value

A `ggplot` object.

## See also

[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)

## Examples

``` r
model <- sim_model(
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1)
)
data <- sim_events(model, n = 10)
plot_event_data(data)


# Custom colors:
plot_event_data(data) +
  ggplot2::scale_color_manual(
    values = c(start = "grey", censoring = "blue", death = "red")
  )
```
