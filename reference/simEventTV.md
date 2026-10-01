# Simulate Event Data with Time-Varying Effects

`simEventTV()` is deprecated as of simevent 0.2.0. Use
[`sim_events()`](https://github.com/BjarkeHautop/simevent/reference/sim_events.md)
instead.

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

  Numeric matrix. Regression coefficients matrix where columns
  correspond to event types (N0, N1, ...) and rows correspond to
  covariates (L0, A0, L1, L2, ...) and event counts (N0, N1, ...). If
  `beta` has rownames, rows are matched by name against covariate/event
  names (any order, any subset; missing rows default to 0) instead of
  requiring a fixed row order. Default is a zero matrix.

- tv_eff:

  Matrix. Time-varying changes to `beta`, applied at time `t_prime`.
  Must have same dimensions as `beta`.

- t_prime:

  Numeric. Time at which `tv_eff` is added to `beta`.

- eta:

  Numeric vector. Shape parameters of the Weibull baseline intensity for
  each event type. Default is 0.1 for all events.

- nu:

  Numeric vector. Scale parameters of the Weibull baseline intensity for
  each event type. Default is 1.1 for all events.

- at_risk:

  Function. Function determining if an individual is at risk for each
  event type, given their current event counts. Takes a numeric vector
  of event counts and returns a binary vector. Default returns 1 for all
  events.

- term_deltas:

  Integer vector. Event types considered terminal (after which no
  further events occur). Default is c(0, 1).

- max_cens:

  Numeric. Maximum censoring time. Events occurring after this time are
  censored. Default is Inf (no maximal censoring).

- add_cov:

  Named list of functions. Functions generating baseline covariates,
  drawn in list order after `L0`/`A0` (unless the list itself supplies
  "L0"/"A0", replacing the defaults). Each function takes integer N and,
  optionally, any subset of the names of covariates defined earlier
  (including L0/A0), matched by argument name, and returns a numeric
  vector of length N. Default is NULL.

- override_beta:

  Named list. Used to specify entries of the `beta` matrix to override
  defaults. For example, `list("L0" = c("N1" = 2))` sets the effect of
  L0 on N1 to 2.

- max_events:

  Integer. Maximum number of events to simulate per individual. Default
  is 10.

- lower:

  Numeric. Lower bound for root-finding in inverse cumulative hazard
  calculations. Default is \\10^{-15}\\.

- upper:

  Numeric. Upper bound for root-finding in inverse cumulative hazard
  calculations. Default is 200.

- gen_A0:

  Function. Deprecated; use `add_cov = list(A0 = ...)` instead. Function
  to generate the baseline treatment covariate A0. Takes N and L0 as
  inputs. Default is a Bernoulli(0.5) random variable.

- gen_L0:

  Function. Deprecated; use `add_cov = list(L0 = ...)` instead. Function
  to generate the baseline covariate L0. Takes N as inputs. Default is a
  Uniform(0,1) random variable.

- at_risk_cov:

  Function. Function determining if an individual is at risk for each
  event type, given their covariates. Takes a matrix of covariates and
  returns a binary matrix. Default returns 1 for all events and all
  individuals.

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

`simEventTV` simulates event data with the option of adding time-varying
effects. The function is built up in the same way as `simEventData`,
with the additional arguments `tv_eff` and `t_prime`, which specify the
change of the beta matrix at time `t_prime`.

## Examples

``` r
eta <- rep(0.1, 2)
simEventTV(N = 100, t_prime = 1, eta = eta, term_deltas = c(0, 1))
#> Warning: `simEventTV()` was deprecated in simevent 0.2.0.
#> ℹ Please use `sim_events()` instead.
#> Key: <ID>
#>         ID        Time Delta         L0    A0    N0    N1
#>      <int>       <num> <int>      <num> <num> <num> <num>
#>   1:     1  9.33858849     0 0.75457704     0     1     0
#>   2:     2  1.08016228     0 0.12411415     1     1     0
#>   3:     3  2.44289909     1 0.33469398     1     0     1
#>   4:     4  3.07898429     1 0.31396663     0     0     1
#>   5:     5 10.15645674     1 0.08361204     1     0     1
#>   6:     6  1.26681398     1 0.13900753     0     0     1
#>   7:     7  6.80631216     1 0.18104854     1     0     1
#>   8:     8  6.01150265     0 0.26162370     1     1     0
#>   9:     9  0.95429145     0 0.20387363     0     1     0
#>  10:    10  0.19867850     1 0.87037492     1     0     1
#>  11:    11  6.79375375     0 0.92629382     0     1     0
#>  12:    12  5.08386331     1 0.93242851     0     0     1
#>  13:    13  0.09288237     0 0.92473129     1     1     0
#>  14:    14 15.10614774     1 0.34660303     0     0     1
#>  15:    15  7.95812942     0 0.75842586     0     1     0
#>  16:    16  0.84858204     0 0.69976180     0     1     0
#>  17:    17 14.93557918     1 0.77106970     0     0     1
#>  18:    18  1.33082252     1 0.21810867     1     0     1
#>  19:    19  0.88562968     1 0.42338195     0     0     1
#>  20:    20  9.22682242     0 0.94062311     1     1     0
#>  21:    21  0.45084748     0 0.94600733     0     1     0
#>  22:    22  4.16625829     0 0.59344008     1     1     0
#>  23:    23  7.98524919     1 0.50343535     0     0     1
#>  24:    24  5.27597241     0 0.14942346     1     1     0
#>  25:    25  3.40079698     0 0.65619920     1     1     0
#>  26:    26  2.69859351     0 0.78155083     0     1     0
#>  27:    27  1.33440767     0 0.73185102     0     1     0
#>  28:    28  0.77914835     1 0.68012770     0     0     1
#>  29:    29  2.94931441     1 0.21359184     1     0     1
#>  30:    30  1.76408952     0 0.52241660     1     1     0
#>  31:    31  4.72046521     0 0.86920169     0     1     0
#>  32:    32  0.48513321     1 0.30260901     0     0     1
#>  33:    33  0.45358506     1 0.43981513     0     0     1
#>  34:    34 10.75365476     0 0.25421923     0     1     0
#>  35:    35  8.29907033     0 0.30233172     0     1     0
#>  36:    36  0.41187349     0 0.23874610     1     1     0
#>  37:    37 13.34538192     0 0.11522158     1     1     0
#>  38:    38  4.94824303     1 0.47997324     1     0     1
#>  39:    39  0.79940647     0 0.73668383     0     1     0
#>  40:    40  7.94611013     1 0.22623484     0     0     1
#>  41:    41  4.35572527     1 0.92283955     1     0     1
#>  42:    42  1.25714767     0 0.26918673     1     1     0
#>  43:    43  3.75239146     0 0.16283759     0     1     0
#>  44:    44  1.85159899     1 0.98269655     1     0     1
#>  45:    45  4.33453695     0 0.01886793     0     1     0
#>  46:    46  1.04931520     1 0.40610555     0     0     1
#>  47:    47 18.16500577     1 0.32474856     0     0     1
#>  48:    48  2.64646303     1 0.73404844     0     0     1
#>  49:    49  0.74503400     0 0.43425165     0     1     0
#>  50:    50  3.82653974     0 0.52284471     1     1     0
#>  51:    51  5.37609082     0 0.81531447     1     1     0
#>  52:    52  0.61267948     1 0.74682697     0     0     1
#>  53:    53  5.58088613     0 0.48823723     1     1     0
#>  54:    54  1.52038716     0 0.23579837     1     1     0
#>  55:    55  0.17875357     0 0.96844307     0     1     0
#>  56:    56  3.87279384     1 0.61191787     1     0     1
#>  57:    57  8.70365971     0 0.11337721     0     1     0
#>  58:    58  3.22807945     1 0.57002311     1     0     1
#>  59:    59  0.73858867     0 0.04436754     0     1     0
#>  60:    60  2.29086409     0 0.76471090     1     1     0
#>  61:    61  6.02237263     0 0.20773780     1     1     0
#>  62:    62  1.60904361     1 0.85788502     0     0     1
#>  63:    63  3.15710870     0 0.89797844     0     1     0
#>  64:    64 11.51042691     0 0.86788091     0     1     0
#>  65:    65  7.29702170     0 0.66577822     0     1     0
#>  66:    66  0.80695334     0 0.38072564     1     1     0
#>  67:    67  4.23302620     1 0.27496030     1     0     1
#>  68:    68  3.25729341     0 0.02343955     0     1     0
#>  69:    69 10.08994728     1 0.29844107     0     0     1
#>  70:    70  1.53885623     0 0.37380841     1     1     0
#>  71:    71  7.48280778     1 0.60758990     0     0     1
#>  72:    72  4.03963068     1 0.84935493     0     0     1
#>  73:    73  0.08579266     1 0.24281278     1     0     1
#>  74:    74  0.08680801     0 0.43817848     0     1     0
#>  75:    75  2.03256409     0 0.84618723     0     1     0
#>  76:    76  5.93555422     1 0.84198006     0     0     1
#>  77:    77  1.22842954     1 0.66388590     1     0     1
#>  78:    78  1.86564978     0 0.55993803     0     1     0
#>  79:    79  9.51977279     0 0.25897893     1     1     0
#>  80:    80  1.44748426     1 0.35083140     0     0     1
#>  81:    81  3.37110449     0 0.64102411     1     1     0
#>  82:    82  3.35734248     0 0.89478728     0     1     0
#>  83:    83  8.62514409     0 0.68283088     0     1     0
#>  84:    84  0.24464022     0 0.92920500     1     1     0
#>  85:    85  0.15003519     0 0.25499938     0     1     0
#>  86:    86  0.10030319     0 0.52915016     1     1     0
#>  87:    87  7.19877480     0 0.48911445     0     1     0
#>  88:    88  2.38714486     1 0.89895526     0     0     1
#>  89:    89  2.65143918     1 0.37912895     0     0     1
#>  90:    90  2.24200668     1 0.32907377     1     0     1
#>  91:    91  6.31414314     1 0.79933220     0     0     1
#>  92:    92  9.00856989     1 0.29849874     0     0     1
#>  93:    93  3.46173032     1 0.74668334     1     0     1
#>  94:    94  0.10148664     1 0.80086617     1     0     1
#>  95:    95  4.45678037     0 0.16954762     1     1     0
#>  96:    96  1.83024814     0 0.71838110     0     1     0
#>  97:    97  3.59786288     1 0.08116455     1     0     1
#>  98:    98  1.51636776     1 0.08198304     0     0     1
#>  99:    99  1.31330427     1 0.42726550     0     0     1
#> 100:   100  3.05997380     0 0.19412911     1     1     0
#>         ID        Time Delta         L0    A0    N0    N1
#>      <int>       <num> <int>      <num> <num> <num> <num>
```
