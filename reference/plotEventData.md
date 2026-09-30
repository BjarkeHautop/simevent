# Plot Simulated Event History Data

`plotEventData()` is deprecated as of simevent 0.2.0. Use
[`plot_event_data()`](https://github.com/BjarkeHautop/simevent/reference/plot_event_data.md)
instead.

## Usage

``` r
plotEventData(data, title = "Event Data")
```

## Arguments

- data:

  A `data.frame` or `data.table` containing at least the columns `ID`,
  `Time`, and `Delta`.

- title:

  Character string specifying the plot title. Defaults to
  `"Event Data"`.

## Value

A `ggplot` object representing the event data visualization.

## Details

Visualizes event history data by plotting individual event times colored
and shaped by event type. Each individual's timeline is displayed
horizontally with events marked along it.

## Examples

``` r
data <- simEventData(10)
plotEventData(data)
#> Warning: `plotEventData()` was deprecated in simevent 0.2.0.
#> ℹ Please use `plot_event_data()` instead.
```
