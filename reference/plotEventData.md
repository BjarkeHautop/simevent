# Plot Simulated Event History Data

Visualizes event history data by plotting individual event times colored
and shaped by event type. Each individual's timeline is displayed
horizontally with events marked along it.

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

## Examples

``` r
data <- simEventData(10)
plotEventData(data)
```
