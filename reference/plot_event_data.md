# Plot Graph-Based Simulated Event History Data

Visualizes
[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)
output by plotting individual event times colored and shaped by event
type. Each individual's timeline is displayed horizontally with events
marked along it.

## Usage

``` r
plot_event_data(data, title = "Event Data")
```

## Arguments

- data:

  A `data.table` as returned by
  [`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md),
  containing at least the columns `id`, `time`, and `delta`.

- title:

  Character string specifying the plot title. Defaults to
  `"Event Data"`.

## Value

A `ggplot` object representing the event data visualization.

## Details

Colors and shapes can be customized by adding
`+ ggplot2::scale_color_manual(...)`/`+ ggplot2::scale_shape_manual(...)`
to the returned plot.

## See also

[`sim_event_graph()`](https://github.com/miclukacova/simevent/reference/sim_event_graph.md)

## Examples

``` r
graph <- sim_graph(
  censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
  death = sim_process("terminal", eta = 0.1, nu = 1.1)
)
data <- sim_event_graph(graph, n = 10)
plot_event_data(data)


# Custom colors:
plot_event_data(data) +
  ggplot2::scale_color_manual(values = c(start = "grey", `0` = "blue", `1` = "red"))
```
