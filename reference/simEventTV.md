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

## Examples

``` r
eta <- rep(0.1, 2)
simEventTV(N = 100, t_prime = 1, eta = eta, term_deltas = c(0, 1))
#> Key: <ID>
#>         ID        Time Delta          L0    A0    N0    N1
#>      <int>       <num> <int>       <num> <num> <num> <num>
#>   1:     1  0.62696841     0 0.841810689     1     1     0
#>   2:     2 10.05504962     0 0.382760536     1     1     0
#>   3:     3  0.83255302     0 0.576344518     0     1     0
#>   4:     4  1.66377019     0 0.188035774     0     1     0
#>   5:     5  1.46887586     1 0.601919837     0     0     1
#>   6:     6  3.06987307     0 0.838748938     1     1     0
#>   7:     7  3.14035381     1 0.265192053     0     0     1
#>   8:     8  3.90580231     1 0.203067929     1     0     1
#>   9:     9  6.02222710     0 0.078322456     1     1     0
#>  10:    10  5.14670720     1 0.331998679     0     0     1
#>  11:    11 10.62741945     0 0.866896609     1     1     0
#>  12:    12  2.18216343     1 0.383193915     1     0     1
#>  13:    13  7.98802255     1 0.917965116     1     0     1
#>  14:    14  1.44760121     1 0.004381784     1     0     1
#>  15:    15  2.15358604     0 0.616581992     0     1     0
#>  16:    16  1.82641330     1 0.757234801     0     0     1
#>  17:    17  6.91619930     1 0.187966605     0     0     1
#>  18:    18  4.63508635     1 0.833125595     0     0     1
#>  19:    19  4.26288412     0 0.247516046     1     1     0
#>  20:    20  0.14303300     1 0.704184470     1     0     1
#>  21:    21  0.31412852     1 0.572449881     0     0     1
#>  22:    22  2.27345944     0 0.202625804     0     1     0
#>  23:    23  0.62284534     0 0.475557717     1     1     0
#>  24:    24  1.92187857     1 0.375886048     0     0     1
#>  25:    25  3.53877766     1 0.375305825     1     0     1
#>  26:    26  1.36141253     1 0.430038428     0     0     1
#>  27:    27  3.26937883     1 0.481093731     0     0     1
#>  28:    28  1.46809872     1 0.580902446     1     0     1
#>  29:    29  3.70707818     1 0.752111772     0     0     1
#>  30:    30 22.55658386     0 0.621328081     0     1     0
#>  31:    31  1.70783151     1 0.581491686     0     0     1
#>  32:    32  3.57236398     0 0.933073354     1     1     0
#>  33:    33  8.90551029     0 0.002877553     0     1     0
#>  34:    34  0.79077718     1 0.524151991     1     0     1
#>  35:    35  0.60181379     1 0.333252484     1     0     1
#>  36:    36  0.36820482     0 0.462785236     1     1     0
#>  37:    37  0.05411252     0 0.843085956     0     1     0
#>  38:    38  2.13808265     1 0.367913673     1     0     1
#>  39:    39 11.03729403     1 0.967603881     0     0     1
#>  40:    40  0.51042377     0 0.196255102     0     1     0
#>  41:    41 12.51359297     0 0.042446758     0     1     0
#>  42:    42  5.79112091     1 0.179921246     1     0     1
#>  43:    43  6.03960828     0 0.246870423     1     1     0
#>  44:    44  4.06861778     0 0.992213292     1     1     0
#>  45:    45  2.85400299     0 0.531815256     1     1     0
#>  46:    46  4.87167191     0 0.504498780     1     1     0
#>  47:    47  2.82041943     0 0.877160561     1     1     0
#>  48:    48  0.44977825     1 0.163691347     0     0     1
#>  49:    49  8.03201297     1 0.669180237     1     0     1
#>  50:    50  6.40921126     0 0.909695591     1     1     0
#>  51:    51  3.91164697     1 0.804452728     1     0     1
#>  52:    52  2.30524960     1 0.833350024     0     0     1
#>  53:    53  3.75063349     1 0.052039192     0     0     1
#>  54:    54  3.33510024     1 0.441444959     0     0     1
#>  55:    55 17.13447371     1 0.407384462     1     0     1
#>  56:    56  2.16899046     1 0.831844814     0     0     1
#>  57:    57  2.89931790     0 0.150882821     0     1     0
#>  58:    58 12.72057121     0 0.082134753     1     1     0
#>  59:    59  2.72004099     0 0.126905578     0     1     0
#>  60:    60 17.12020257     1 0.721911898     0     0     1
#>  61:    61  3.62611521     0 0.064012451     0     1     0
#>  62:    62  1.14991334     1 0.048750827     0     0     1
#>  63:    63  4.36296837     1 0.225156905     0     0     1
#>  64:    64  7.53996344     1 0.873166104     1     0     1
#>  65:    65  3.26534359     0 0.320335118     1     1     0
#>  66:    66  0.52203507     0 0.207378254     1     1     0
#>  67:    67  1.32025208     0 0.523557742     1     1     0
#>  68:    68  5.68254890     0 0.086926059     0     1     0
#>  69:    69  5.01103584     0 0.921215981     1     1     0
#>  70:    70  0.45439086     1 0.049349079     1     0     1
#>  71:    71  3.86980677     1 0.756114093     1     0     1
#>  72:    72  4.54579778     0 0.131296139     1     1     0
#>  73:    73  1.80170207     1 0.847805935     0     0     1
#>  74:    74  2.63797949     1 0.579836848     1     0     1
#>  75:    75  0.95927157     1 0.180546294     0     0     1
#>  76:    76  1.99985976     1 0.880178357     0     0     1
#>  77:    77  5.98889233     0 0.029000303     0     1     0
#>  78:    78  4.56322348     1 0.806299404     0     0     1
#>  79:    79  3.02941750     1 0.396571558     1     0     1
#>  80:    80 18.27563265     1 0.896704034     0     0     1
#>  81:    81  5.42097054     1 0.710434539     1     0     1
#>  82:    82  0.56325048     0 0.947976480     0     1     0
#>  83:    83  2.24050556     1 0.317747798     0     0     1
#>  84:    84  6.74851050     0 0.822975165     1     1     0
#>  85:    85  8.47247206     0 0.463486072     1     1     0
#>  86:    86  9.02344167     0 0.518518004     1     1     0
#>  87:    87  0.04402716     0 0.162162409     0     1     0
#>  88:    88  0.71366965     0 0.050351400     0     1     0
#>  89:    89 11.47990181     0 0.100550561     1     1     0
#>  90:    90  1.22133757     0 0.870112007     0     1     0
#>  91:    91  0.67799520     1 0.728581335     1     0     1
#>  92:    92  0.24677546     0 0.765673450     0     1     0
#>  93:    93 12.43957550     1 0.151354960     0     0     1
#>  94:    94  7.71408286     1 0.177549925     1     0     1
#>  95:    95  1.85075269     1 0.396286517     0     0     1
#>  96:    96  4.04043461     1 0.995582125     0     0     1
#>  97:    97 11.18518901     1 0.904936575     0     0     1
#>  98:    98  1.10324877     0 0.787012418     1     1     0
#>  99:    99  1.95854457     1 0.337500844     1     0     1
#> 100:   100  4.98406371     1 0.194293272     1     0     1
#>         ID        Time Delta          L0    A0    N0    N1
#>      <int>       <num> <int>       <num> <num> <num> <num>
```
