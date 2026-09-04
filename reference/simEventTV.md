# Simulate Event Data with Time-Varying Effects

`simEventTV` simulates event data with the option of adding time-varying
effects. The function is built up in the same way as `simEventData`,
with the additional arguments `tv_eff` and `t_prime`, which specify the
change of the beta matrix at time `t_prime`.

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
  covariates (L0, A0, L1, L2, ...) and event counts (N0, N1, ...).
  Default is a zero matrix.

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

  Named list of functions. Functions generating additional baseline
  covariates. Each function takes integer N and returns a numeric vector
  of length N. Default is NULL.

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

  Function. Function to generate the baseline treatment covariate A0.
  Takes N and L0 as inputs. Default is a Bernoulli(0.5) random variable.

- gen_L0:

  Function. Function to generate the baseline covariate L0. Takes N as
  inputs. Default is a Uniform(0,1) random variable.

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

## Examples

``` r
eta <- rep(0.1, 2)
simEventTV(N = 100, t_prime = 1, eta = eta, term_deltas = c(0, 1))
#> Key: <ID>
#>         ID        Time Delta         L0    A0    N0    N1
#>      <int>       <num> <int>      <num> <num> <num> <num>
#>   1:     1  2.69446985     1 0.76801165     0     0     1
#>   2:     2  0.55943322     1 0.33133865     0     0     1
#>   3:     3  2.43773701     1 0.29268886     1     0     1
#>   4:     4  2.80797212     1 0.35314392     0     0     1
#>   5:     5  0.57231791     0 0.36285441     1     1     0
#>   6:     6  3.30922670     1 0.88122362     0     0     1
#>   7:     7  1.74769561     1 0.92227965     0     0     1
#>   8:     8  8.15060709     1 0.23924843     1     0     1
#>   9:     9  3.98052727     0 0.07053280     1     1     0
#>  10:    10  4.93924515     0 0.11478203     1     1     0
#>  11:    11  5.29772515     0 0.31351050     1     1     0
#>  12:    12  2.01772870     1 0.00337860     1     0     1
#>  13:    13  6.12429351     0 0.12736157     1     1     0
#>  14:    14  1.22540104     0 0.13752427     0     1     0
#>  15:    15  8.92275491     1 0.49099112     1     0     1
#>  16:    16  2.86931153     0 0.40860034     1     1     0
#>  17:    17  0.24104302     1 0.24130682     0     0     1
#>  18:    18 10.38444460     0 0.85878000     1     1     0
#>  19:    19  4.82997581     0 0.41266502     1     1     0
#>  20:    20  7.31900112     1 0.80925287     0     0     1
#>  21:    21  0.70121934     0 0.15693721     0     1     0
#>  22:    22  0.66287629     0 0.02164343     0     1     0
#>  23:    23  1.06636065     0 0.67488461     0     1     0
#>  24:    24 10.87020402     0 0.06629634     1     1     0
#>  25:    25  0.06216451     1 0.58778033     0     0     1
#>  26:    26  4.07739695     1 0.41307524     1     0     1
#>  27:    27  9.13956432     0 0.57658254     0     1     0
#>  28:    28  2.11356579     0 0.91511614     1     1     0
#>  29:    29  7.41940506     0 0.25422140     1     1     0
#>  30:    30  1.00854082     1 0.04755338     0     0     1
#>  31:    31  6.06806833     0 0.56554766     0     1     0
#>  32:    32  3.02825788     1 0.16234537     0     0     1
#>  33:    33  7.56957673     1 0.34094857     1     0     1
#>  34:    34  3.22098188     0 0.96632196     0     1     0
#>  35:    35  2.79426419     0 0.63184025     1     1     0
#>  36:    36  7.62678570     1 0.44427705     0     0     1
#>  37:    37  2.40399229     0 0.89336838     0     1     0
#>  38:    38  0.33968743     1 0.51360348     1     0     1
#>  39:    39  0.28844444     1 0.86464469     0     0     1
#>  40:    40  0.06497117     1 0.06107494     0     0     1
#>  41:    41  9.13388786     1 0.76151738     0     0     1
#>  42:    42  0.34930261     0 0.62887125     1     1     0
#>  43:    43  1.01564553     1 0.03918682     0     0     1
#>  44:    44  5.65376747     0 0.44173238     1     1     0
#>  45:    45  2.79417955     1 0.50641194     1     0     1
#>  46:    46  6.72969604     1 0.28499016     1     0     1
#>  47:    47  4.90626540     1 0.82663997     0     0     1
#>  48:    48 13.54789796     1 0.72287086     1     0     1
#>  49:    49  1.39354178     1 0.37935489     1     0     1
#>  50:    50  3.71010466     1 0.26894813     1     0     1
#>  51:    51  3.93333866     0 0.41517841     0     1     0
#>  52:    52 15.29191305     0 0.77541463     0     1     0
#>  53:    53  3.93971809     1 0.46596599     1     0     1
#>  54:    54  1.37304406     1 0.65600636     0     0     1
#>  55:    55  1.93603107     1 0.43128560     0     0     1
#>  56:    56  0.26798232     0 0.63374326     0     1     0
#>  57:    57  2.60957515     1 0.48982975     1     0     1
#>  58:    58  3.51139284     0 0.97427544     0     1     0
#>  59:    59  1.04031675     0 0.48054427     0     1     0
#>  60:    60 11.37018503     1 0.65524363     0     0     1
#>  61:    61  0.88906127     1 0.34494113     1     0     1
#>  62:    62 19.37688413     1 0.05678969     0     0     1
#>  63:    63  2.27474889     1 0.90931028     0     0     1
#>  64:    64  7.18410337     1 0.81813508     0     0     1
#>  65:    65  0.96407452     1 0.36255885     0     0     1
#>  66:    66  3.68765325     0 0.42654194     1     1     0
#>  67:    67 10.18664909     1 0.45228300     1     0     1
#>  68:    68  0.09507430     1 0.24124680     0     0     1
#>  69:    69  0.22324108     1 0.85268743     1     0     1
#>  70:    70  4.40797908     1 0.35706573     1     0     1
#>  71:    71  3.94183479     0 0.90356171     1     1     0
#>  72:    72 15.50952837     1 0.23594917     0     0     1
#>  73:    73  3.58061980     1 0.71452677     1     0     1
#>  74:    74  5.94306513     1 0.16266392     0     0     1
#>  75:    75  0.26496095     1 0.63635186     1     0     1
#>  76:    76  8.25738889     1 0.69939320     0     0     1
#>  77:    77  0.43791304     0 0.58601024     1     1     0
#>  78:    78  2.07959822     0 0.72914698     1     1     0
#>  79:    79  0.40295049     1 0.13714396     1     0     1
#>  80:    80  7.84812502     0 0.34542319     1     1     0
#>  81:    81  3.04301149     0 0.35441411     1     1     0
#>  82:    82 13.30996486     0 0.08391297     0     1     0
#>  83:    83  0.99010074     0 0.57250921     1     1     0
#>  84:    84  3.40682580     0 0.66189654     1     1     0
#>  85:    85  1.12446661     0 0.46969831     1     1     0
#>  86:    86  6.73363449     1 0.55471833     0     0     1
#>  87:    87  6.45215015     0 0.29677432     1     1     0
#>  88:    88 10.37411434     0 0.89003743     0     1     0
#>  89:    89  1.85681655     0 0.13009405     0     1     0
#>  90:    90 10.34070163     1 0.99432276     0     0     1
#>  91:    91  2.20910541     0 0.02923233     1     1     0
#>  92:    92  3.10647898     0 0.07374979     1     1     0
#>  93:    93  0.58580835     0 0.32261196     1     1     0
#>  94:    94 10.41001951     0 0.63839810     0     1     0
#>  95:    95 17.45178147     1 0.15854881     1     0     1
#>  96:    96  4.36786212     1 0.23705496     0     0     1
#>  97:    97  1.95400176     0 0.02818888     0     1     0
#>  98:    98  6.50063186     0 0.78553091     1     1     0
#>  99:    99  3.94637488     0 0.70200717     0     1     0
#> 100:   100  4.57308258     1 0.43092455     0     0     1
#>         ID        Time Delta         L0    A0    N0    N1
#>      <int>       <num> <int>      <num> <num> <num> <num>
```
