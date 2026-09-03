# simEventTV

Simulate Event Data with Time-Varying Effects

## Usage

``` r
simEventTV(
  N,
  beta = NULL,
  tv_eff = NULL,
  t_prime = Inf,
  eta = NULL,
  nu = NULL,
  at_risk = NULL,
  term_deltas = c(0, 1),
  max_cens = Inf,
  add_cov = NULL,
  override_beta = NULL,
  max_events = 10,
  lower = 10^(-15),
  upper = 200,
  gen_A0 = NULL,
  gen_L0 = NULL,
  at_risk_cov = NULL
)
```

## Arguments

- N:

  Integer. Number of individuals to simulate.

- beta:

  Matrix. Coefficients for covariates and processes. Columns correspond
  to events (`N0`, `N1`, ...), rows correspond to covariates (`L0`,
  `A0`, ..., and past event counts).

- tv_eff:

  Matrix. Time-varying changes to `beta`, applied at time `t_prime`.
  Must have same dimensions as `beta`.

- t_prime:

  Numeric. Time at which `tv_eff` is added to `beta`.

- eta:

  Numeric vector. Shape parameters of Weibull intensities for each
  event.

- nu:

  Numeric vector. Scale parameters of Weibull intensities for each
  event.

- at_risk:

  Function. Determines which events an individual is at risk for, based
  on event history.

- term_deltas:

  Integer vector. Event types considered terminal (e.g., death).

- max_cens:

  Numeric. Maximum censoring time. Defaults to `Inf`.

- add_cov:

  Named list of functions for generating additional baseline covariates.
  Each function takes one argument `N` and returns a vector of length
  `N`.

- override_beta:

  Named list to override elements of `beta`. Format:
  `list("covariate" = c("event" = value))`.

- max_events:

  Integer. Maximum number of events allowed per individual.

- lower:

  Numeric. Lower bound for the root-finding algorithm used in inverse
  cumulative hazard computation.

- upper:

  Numeric. Upper bound for the root-finding algorithm used in inverse
  cumulative hazard computation.

- gen_A0:

  Function. Generates baseline treatment assignment. Takes arguments `N`
  and `L0`.

- gen_L0:

  Function. Function to generate the baseline covariate L0. Takes N as
  input. Default is a Uniform(0,1) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a numeric vector covariates
  and returns a binary vector. Default returns 1 for all events.

## Value

A `data.table` with columns:

- ID::

  Individual identifier

- Time::

  Time of event

- Delta::

  Type of event

- L0::

  Baseline covariate

- A0::

  Baseline treatment

- N0, N1, ...::

  Cumulative event counts

- L1, L2, ...::

  Additional covariates (if specified)

## Details

`simEventTV` is a function that simulates event data, with the option of
adding time varying effects. The function is build up in the same way as
`simEventData`, with the additional arguments `tv_eff` and `t_prime`,
which specify the change of the beta matrix at time `t_prime`.

## Examples

``` r
eta <- rep(0.1, 2)
simEventTV(N = 100, t_prime = 1, eta = eta, term_deltas = c(0, 1))
#> Key: <ID>
#>         ID        Time Delta          L0    A0    N0    N1
#>      <int>       <num> <int>       <num> <num> <num> <num>
#>   1:     1  1.41304132     0 0.123659201     1     1     0
#>   2:     2  3.05578246     0 0.084049511     1     1     0
#>   3:     3  0.40390969     0 0.353033728     0     1     0
#>   4:     4  4.46009376     1 0.732354276     0     0     1
#>   5:     5 11.42930461     1 0.422132129     0     0     1
#>   6:     6 18.53551997     0 0.472886229     0     1     0
#>   7:     7  8.78798314     1 0.038318015     0     0     1
#>   8:     8  0.52934199     1 0.076113100     0     0     1
#>   9:     9 10.15159015     1 0.945357663     0     0     1
#>  10:    10  9.26260616     1 0.616021806     1     0     1
#>  11:    11  1.77438848     1 0.854396588     0     0     1
#>  12:    12  8.59358367     1 0.800628803     1     0     1
#>  13:    13  3.86419923     0 0.542193091     0     1     0
#>  14:    14  0.77548521     1 0.694144351     1     0     1
#>  15:    15  0.93849248     1 0.138043712     0     0     1
#>  16:    16  5.86055527     1 0.963347081     0     0     1
#>  17:    17  6.99100152     0 0.295585640     0     1     0
#>  18:    18  0.35345139     1 0.759940883     0     0     1
#>  19:    19  2.12691720     1 0.594194551     0     0     1
#>  20:    20  3.05192190     1 0.887815378     0     0     1
#>  21:    21  6.02066999     0 0.168574071     0     1     0
#>  22:    22  3.77239368     1 0.510353506     0     0     1
#>  23:    23  9.28519231     1 0.384177614     1     0     1
#>  24:    24  4.03046982     1 0.627224933     1     0     1
#>  25:    25  2.54754552     0 0.836510315     0     1     0
#>  26:    26  0.59518601     1 0.550652486     1     0     1
#>  27:    27  2.30120350     1 0.491388189     1     0     1
#>  28:    28  4.58778240     0 0.602477242     0     1     0
#>  29:    29  4.96041984     1 0.228910912     0     0     1
#>  30:    30  0.04414789     0 0.906212895     0     1     0
#>  31:    31  5.79269975     1 0.153277569     1     0     1
#>  32:    32  8.00951734     1 0.460643962     0     0     1
#>  33:    33  3.42655675     0 0.641429743     1     1     0
#>  34:    34  5.36895980     1 0.956208388     0     0     1
#>  35:    35  6.39714715     1 0.642729964     1     0     1
#>  36:    36  4.28867193     0 0.022599353     1     1     0
#>  37:    37  1.08499620     0 0.006789963     1     1     0
#>  38:    38  1.62981406     0 0.177222281     1     1     0
#>  39:    39  0.26599707     0 0.248172282     0     1     0
#>  40:    40  4.46680892     1 0.249792372     0     0     1
#>  41:    41  1.21574990     1 0.671568735     1     0     1
#>  42:    42  0.94498367     1 0.427087614     1     0     1
#>  43:    43 11.43994250     1 0.408860861     1     0     1
#>  44:    44 11.36600148     0 0.504627512     0     1     0
#>  45:    45  1.96660957     0 0.856904741     1     1     0
#>  46:    46  2.01386121     0 0.337679865     1     1     0
#>  47:    47  4.93352450     0 0.839973625     1     1     0
#>  48:    48  4.75662983     0 0.171190976     1     1     0
#>  49:    49  0.27176897     1 0.247848177     0     0     1
#>  50:    50  8.72871636     1 0.764831232     0     0     1
#>  51:    51  3.43769109     0 0.328584575     1     1     0
#>  52:    52  1.42574182     0 0.837585814     1     1     0
#>  53:    53  2.61125064     0 0.456451075     0     1     0
#>  54:    54  2.03738150     1 0.321235984     0     0     1
#>  55:    55  1.23531726     1 0.972401744     0     0     1
#>  56:    56  1.60042379     0 0.161270830     0     1     0
#>  57:    57  3.56225172     0 0.840165054     0     1     0
#>  58:    58  5.37339107     1 0.157019802     0     0     1
#>  59:    59  2.16714729     0 0.910982558     1     1     0
#>  60:    60  0.26496500     0 0.033139684     1     1     0
#>  61:    61  5.53653316     0 0.230993975     0     1     0
#>  62:    62  8.04294950     0 0.663502625     1     1     0
#>  63:    63 10.74347806     1 0.254671853     1     0     1
#>  64:    64  1.78139049     1 0.445062147     1     0     1
#>  65:    65 20.44948424     1 0.270396854     0     0     1
#>  66:    66  8.59596436     0 0.440451815     1     1     0
#>  67:    67  2.64557386     0 0.759953021     0     1     0
#>  68:    68  6.38077786     0 0.782070135     0     1     0
#>  69:    69 12.37513300     0 0.067589953     1     1     0
#>  70:    70  3.30035068     1 0.136182614     1     0     1
#>  71:    71  3.90026337     1 0.542649451     1     0     1
#>  72:    72  0.59578838     1 0.523240606     1     0     1
#>  73:    73  6.46208125     0 0.352643339     1     1     0
#>  74:    74  7.61667000     1 0.231016776     0     0     1
#>  75:    75  1.28143731     1 0.845248392     1     0     1
#>  76:    76  3.82123083     0 0.674021854     0     1     0
#>  77:    77  0.62457116     1 0.865255159     0     0     1
#>  78:    78  1.36193791     1 0.777805390     1     0     1
#>  79:    79  6.60147591     1 0.902425118     0     0     1
#>  80:    80  1.63335792     1 0.689836058     0     0     1
#>  81:    81  7.21559393     0 0.282208983     0     1     0
#>  82:    82  7.91075901     1 0.501307420     1     0     1
#>  83:    83  0.88365030     0 0.074912051     0     1     0
#>  84:    84  2.72933100     0 0.027647098     0     1     0
#>  85:    85  2.22694465     1 0.946769265     1     0     1
#>  86:    86  1.05095200     1 0.849427535     0     0     1
#>  87:    87  0.51332379     1 0.260248319     0     0     1
#>  88:    88  8.25277913     0 0.164935153     1     1     0
#>  89:    89  1.07017276     1 0.367601909     1     0     1
#>  90:    90  2.60416664     1 0.281419025     1     0     1
#>  91:    91  4.75978982     0 0.794593781     0     1     0
#>  92:    92  9.48051350     0 0.069243586     0     1     0
#>  93:    93 10.77378833     0 0.149394132     1     1     0
#>  94:    94  8.99665215     1 0.908485878     1     0     1
#>  95:    95 16.00144646     1 0.012670558     0     0     1
#>  96:    96  4.98693710     0 0.060839276     0     1     0
#>  97:    97  3.50860439     1 0.603984766     0     0     1
#>  98:    98  7.17698284     0 0.949122385     0     1     0
#>  99:    99  6.30778124     1 0.214724828     0     0     1
#> 100:   100  3.18450292     0 0.557592064     1     1     0
#>         ID        Time Delta          L0    A0    N0    N1
#>      <int>       <num> <int>       <num> <num> <num> <num>
```
