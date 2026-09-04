# Transform Event Data into Interval Format for Classical Inference

Converts simulated event history data with time-dependent covariates
into an interval (start-stop) format, suitable for classical survival
analysis functions like `coxph`. Adds interval start and stop times
(`tstart`, `tstop`) and a counting variable `k` indexing events.
Optionally, the function can split intervals at a specified time point
to accommodate estimation of time-varying effects.

## Usage

``` r
IntFormatData(data, N_cols = 6:9, timeVar = FALSE, t_prime = NULL)
```

## Arguments

- data:

  A `data.frame` or `data.table` containing event data with columns
  `ID`, `Time`, `Delta`, and counting process columns specified by
  `N_cols`.

- N_cols:

  Integer vector. Column indices of `data` that correspond to counting
  process variables. Defaults to `6:9`.

- timeVar:

  Logical. If `TRUE`, the intervals are split at `t_prime` to allow
  time-varying covariate effects. Default is `FALSE`.

- t_prime:

  Numeric scalar. Time point at which to split intervals if
  `timeVar = TRUE`.

## Value

A `data.table` with columns `tstart`, `tstop`, `k`, and other original
variables, formatted for survival analysis.

## Examples

``` r
data <- simEventData(10)
IntFormatData(data)
#>        ID       Time Delta          L0    A0    N0    N1    N2    N3     k
#>     <int>      <num> <int>       <num> <num> <num> <num> <num> <num> <int>
#>  1:     1 2.79340256     0 0.080750138     1     0     0     0     0     1
#>  2:     2 0.97279689     0 0.834333037     0     0     0     0     0     1
#>  3:     3 0.78723457     1 0.600760886     0     0     0     0     0     1
#>  4:     4 3.58614539     2 0.157208442     0     0     0     0     0     1
#>  5:     4 4.40759522     1 0.157208442     0     0     0     1     0     2
#>  6:     5 0.06461282     1 0.007399441     0     0     0     0     0     1
#>  7:     6 0.76765933     1 0.466393497     0     0     0     0     0     1
#>  8:     7 6.18261399     2 0.497777389     0     0     0     0     0     1
#>  9:     7 6.67656854     1 0.497777389     0     0     0     1     0     2
#> 10:     8 1.52104484     3 0.289767245     0     0     0     0     0     1
#> 11:     8 1.54136731     0 0.289767245     0     0     0     0     1     2
#> 12:     9 0.91476043     0 0.732881987     0     0     0     0     0     1
#> 13:    10 0.93880609     0 0.772521511     1     0     0     0     0     1
#>       tstart      tstop
#>        <num>      <num>
#>  1: 0.000000 2.79340256
#>  2: 0.000000 0.97279689
#>  3: 0.000000 0.78723457
#>  4: 0.000000 3.58614539
#>  5: 3.586145 4.40759522
#>  6: 0.000000 0.06461282
#>  7: 0.000000 0.76765933
#>  8: 0.000000 6.18261399
#>  9: 6.182614 6.67656854
#> 10: 0.000000 1.52104484
#> 11: 1.521045 1.54136731
#> 12: 0.000000 0.91476043
#> 13: 0.000000 0.93880609
```
