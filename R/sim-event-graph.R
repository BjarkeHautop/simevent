#----------------------------------------------------------------------
## The graph-based API: node/edge constructors, sim_graph(),
## sim_event_graph() and sim_graph_from_fits(). The engine itself lives in
## sim-graph-engine.R.
#----------------------------------------------------------------------

#' Define a Baseline Covariate for `sim_graph()`
#'
#' @param generator Function of `N` (number of individuals) returning the
#'   covariate's values. May also take covariates defined earlier in the same
#'   [sim_graph()] call, by name.
#'
#' @return An object of class `sim_covariate`, for use in [sim_graph()].
#' @seealso [sim_graph()], [sim_process()]
#' @examples
#' # A covariate that doesn't depend on any other:
#' sim_covariate(function(N) rnorm(N, mean = 50, sd = 10))
#'
#' # A covariate whose generator depends on another covariate defined
#' # earlier in the same sim_graph() call:
#' sim_covariate(function(N, age) rbinom(N, 1, plogis(-2 + 0.03 * age)))
#' @export
sim_covariate <- function(generator) {
  checkmate::assert_function(generator)
  if (!("N" %in% names(formals(generator)))) {
    stop(
      "sim_covariate()'s generator must have a formal argument named 'N' ",
      "(the number of individuals to simulate); got formal argument(s): ",
      paste(names(formals(generator)), collapse = ", ")
    )
  }
  structure(list(generator = generator), class = "sim_covariate")
}

#' Define a Derived Covariate for `sim_graph()`
#'
#' `sim_derived` builds a covariate that is a deterministic transform of one
#' or more other covariates defined earlier in the same [sim_graph()] call.
#'
#' @param fn Function of covariates defined earlier in the same
#'   [sim_graph()] call, by name.
#'
#' @return An object of class `sim_derived`, for use in [sim_graph()].
#' @seealso [sim_graph()], [sim_covariate()], [sim_effect()]
#' @examples
#' # BMI from weight (kg) and height (m), stored as its own column and usable
#' # by covariates defined after it:
#' graph <- sim_graph(
#'   weight = sim_covariate(function(N) rnorm(N, mean = 80, sd = 12)),
#'   height = sim_covariate(function(N) rnorm(N, mean = 1.75, sd = 0.08)),
#'   bmi = sim_derived(function(weight, height) weight / height^2),
#'   statin = sim_covariate(function(N, bmi) rbinom(N, 1, plogis(-5 + 0.15 * bmi))),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(sim_effect("statin", "death", coef = -0.3))
#' )
#' head(sim_event_graph(graph, n = 5))
#' @export
sim_derived <- function(fn) {
  checkmate::assert_function(fn)
  if ("N" %in% names(formals(fn))) {
    stop(
      "sim_derived()'s fn should not take 'N'; it's a deterministic ",
      "transform of other covariates, not a random generator. Use ",
      "sim_covariate() for a generator that draws new values."
    )
  }
  if (length(formals(fn)) == 0) {
    stop("sim_derived()'s fn must depend on at least one other covariate.")
  }
  structure(list(fn = fn), class = "sim_derived")
}

# Wraps a sim_derived() fn into a generator simEventShared's
# .simEvent_draw_baseline() can call like any other add_cov entry (which
# always passes N first).
.sim_graph_wrap_derived <- function(fn) {
  wrapper <- function() {}
  formals(wrapper) <- c(alist(N = ), formals(fn))
  body(wrapper) <- as.call(c(quote(fn), lapply(names(formals(fn)), as.symbol)))
  environment(wrapper) <- list2env(list(fn = fn), parent = environment(fn))
  wrapper
}

#' Define an Event Process for `sim_graph()`
#'
#' `sim_process` builds an event process whose baseline intensity is Weibull,
#' \deqn{\lambda_0(t) = \eta \nu t^{\nu - 1},}
#' i.e. cumulative baseline hazard \eqn{\eta t^\nu}. [sim_effect()]s into the
#' process multiply this baseline by \eqn{\exp(\text{coef} \times
#' \text{from})}.
#'
#' @param type One of:
#'   \describe{
#'     \item{`"censoring"`}{Ends follow-up without an outcome event.}
#'     \item{`"terminal"`}{An outcome event ending follow-up (e.g. death).}
#'     \item{`"transient"`}{An event that doesn't end follow-up and can
#'       recur (e.g. relapse).}
#'   }
#' @param eta Numeric. Weibull scale parameter.
#' @param nu Numeric. Weibull shape parameter: `nu > 1` gives an increasing
#'   hazard, `nu < 1` a decreasing one, `nu = 1` a constant one.
#' @param limit Integer or `Inf`. Maximum number of events of a
#'   `"transient"` process. Default `Inf`.
#'
#' @return An object of class `sim_process`, for use in [sim_graph()].
#' @seealso [sim_graph()], [sim_covariate()]
#' @examples
#' # Death, with a slowly increasing hazard:
#' sim_process("terminal", eta = 0.1, nu = 1.1)
#'
#' # A relapse process that can fire at most twice:
#' sim_process("transient", eta = 0.2, nu = 1, limit = 2)
#' @export
sim_process <- function(
  type = c("censoring", "terminal", "transient"),
  eta,
  nu,
  limit = Inf
) {
  type <- match.arg(type)
  checkmate::assert_number(eta, lower = 0, finite = TRUE)
  checkmate::assert_number(nu, lower = 0, finite = TRUE)
  checkmate::assert(
    checkmate::check_count(limit, positive = TRUE),
    checkmate::check_choice(limit, Inf)
  )
  structure(
    list(type = type, eta = eta, nu = nu, limit = limit),
    class = "sim_process"
  )
}

#' Define an Effect for `sim_graph()`
#'
#' Multiplies the hazard of process `to` by `exp(coef * from)`.
#'
#' @param from Character. A covariate name (its value), a process name (its
#'   number of events so far), or an R expression of these. Expressions may
#'   also use:
#'   \describe{
#'     \item{`t`}{The current time (see [sim_event_graph()]'s `time_step`).}
#'     \item{`last_time(proc)`}{Time of `proc`'s latest event, `-Inf` if
#'       none.}
#'     \item{`nth_time(proc, k)`}{Time of `proc`'s `k`-th event, `Inf` if
#'       fewer than `k`.}
#'   }
#' @param to Character. Name of the affected process.
#' @param coef Numeric. Cox-type coefficient.
#'
#' @return An object of class `sim_effect`, for use in [sim_graph()].
#' @seealso [sim_graph()]
#' @examples
#' sim_effect("age", "death", coef = 0.03)
#' sim_effect("(age - 60)^2", "death", coef = 0.001)
#' sim_effect("relapse == 3", "death", coef = 1.2)
#' sim_effect("t - last_time(checkup) < 1", "death", coef = 0.5)
#' sim_effect("t >= nth_time(relapse, 3)", "death", coef = 0.8)
#' @export
sim_effect <- function(from, to, coef) {
  checkmate::assert_string(from)
  checkmate::assert_string(to)
  checkmate::assert_number(coef, finite = TRUE)
  structure(list(from = from, to = to, coef = coef), class = "sim_effect")
}

#' Build a Simulation Graph for `sim_event_graph()`
#'
#' `sim_graph` assembles a set of named [sim_covariate()]/[sim_derived()]/
#' [sim_process()] nodes and [sim_effect()] edges between them into a single
#' specification, which [sim_event_graph()] can then simulate from.
#'
#' @param ... Named [sim_covariate()]/[sim_derived()]/[sim_process()]
#'   objects. A covariate may only depend on covariates listed before it.
#' @param effects List of [sim_effect()]s.
#'
#' @return An object of class `sim_graph`.
#' @seealso [sim_event_graph()], [sim_covariate()], [sim_derived()],
#'   [sim_process()], [sim_effect()]
#' @examples
#' graph <- sim_graph(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.03),
#'     sim_effect("(age - 60)^2", "death", coef = 0.001)
#'   )
#' )
#' graph
#' @export
sim_graph <- function(..., effects = list()) {
  nodes <- list(...)
  checkmate::assert_list(nodes, names = "unique", min.len = 1)

  is_baseline <- vapply(
    nodes,
    inherits,
    logical(1),
    what = c("sim_covariate", "sim_derived")
  )
  is_process <- vapply(nodes, inherits, logical(1), what = "sim_process")
  if (!all(is_baseline | is_process)) {
    stop(
      "All named arguments to sim_graph() must be sim_covariate(), ",
      "sim_derived(), or sim_process() objects; offending name(s): ",
      paste(names(nodes)[!(is_baseline | is_process)], collapse = ", ")
    )
  }
  if (!any(is_process)) {
    stop("sim_graph() needs at least one sim_process().")
  }

  # Names that would collide with sim_event_graph()'s output columns, with
  # the non-process labels its `event` column can take, or with the
  # variables available inside a sim_effect() expression.
  reserved_names <- c(
    "id",
    "time",
    "event",
    "max_cens",
    "none",
    "t",
    "last_time",
    "nth_time"
  )
  reserved <- intersect(names(nodes), reserved_names)
  if (length(reserved) > 0) {
    stop(
      "sim_graph() node name(s) are reserved: ",
      paste(reserved, collapse = ", "),
      ". Reserved names are ",
      paste(reserved_names, collapse = ", "),
      "."
    )
  }
  process_types <- vapply(nodes[is_process], `[[`, character(1), "type")
  if (!any(process_types == "terminal")) {
    stop(
      "sim_graph() needs at least one sim_process(\"terminal\"): without ",
      "one, follow-up never ends."
    )
  }

  baseline_names <- names(nodes)[is_baseline]
  for (nm in baseline_names) {
    node <- nodes[[nm]]
    earlier <- baseline_names[seq_len(match(nm, baseline_names) - 1)]
    if (inherits(node, "sim_covariate")) {
      missing <- setdiff(names(formals(node$generator)), c("N", earlier))
      if (length(missing) > 0) {
        stop(
          "sim_covariate() '",
          nm,
          "' has argument(s) '",
          paste(missing, collapse = ", "),
          "' that do not name an earlier sim_covariate()/sim_derived() in ",
          "the same sim_graph() call."
        )
      }
    }
    if (inherits(node, "sim_derived")) {
      missing <- setdiff(names(formals(node$fn)), earlier)
      if (length(missing) > 0) {
        stop(
          "sim_derived() '",
          nm,
          "' depends on '",
          paste(missing, collapse = ", "),
          "', which must be an earlier sim_covariate()/sim_derived() in ",
          "the same sim_graph() call."
        )
      }
    }
  }

  checkmate::assert_list(effects, types = "sim_effect")
  process_names <- names(nodes)[is_process]
  effect_keys <- vapply(
    effects,
    function(eff) paste(eff$from, eff$to, sep = " -> "),
    character(1)
  )
  if (anyDuplicated(effect_keys) > 0) {
    stop(
      "sim_graph() has duplicate sim_effect()s: ",
      paste(unique(effect_keys[duplicated(effect_keys)]), collapse = "; "),
      ". Combine them into a single effect."
    )
  }
  # A censoring or terminal process ends follow-up, so it can never be
  # observed as a cause of a later event.
  ended <- names(nodes)[is_process][process_types != "transient"]
  for (i in seq_along(effects)) {
    eff <- effects[[i]]
    if (!(eff$from %in% names(nodes))) {
      # Not a bare node name: must be a valid R expression whose free
      # variables are all covariate/process names (or `t`); last_time()/
      # nth_time() take a process name as an unevaluated argument, which
      # all.vars() still picks up as a reference to validate here.
      parsed <- tryCatch(
        str2lang(eff$from),
        error = function(e) {
          stop(
            "sim_effect() 'from' is neither a node name nor a parseable R ",
            "expression: '",
            eff$from,
            "'"
          )
        }
      )
      used <- setdiff(all.vars(parsed), "t")
      unknown <- setdiff(used, names(nodes))
      if (length(unknown) > 0) {
        stop(
          "sim_effect() 'from' expression '",
          eff$from,
          "' references name(s) not found in graph: ",
          paste(unknown, collapse = ", ")
        )
      }
      eff$parsed_from <- parsed
      effects[[i]] <- eff
    }
    if (!(eff$to %in% process_names)) {
      stop(
        "sim_effect() 'to' must name a sim_process() in the graph; '",
        eff$to,
        "' is not one."
      )
    }
    sources <- if (eff$from %in% names(nodes)) {
      eff$from
    } else {
      setdiff(all.vars(eff$parsed_from), "t")
    }
    bad_source <- intersect(sources, ended)
    if (length(bad_source) > 0) {
      stop(
        "sim_effect() 'from' cannot use censoring/terminal process(es) ",
        paste(bad_source, collapse = ", "),
        ": they end follow-up, so never precede another event."
      )
    }
  }

  structure(
    list(
      covariates = nodes[is_baseline],
      processes = nodes[is_process],
      effects = effects
    ),
    class = "sim_graph"
  )
}

#' @export
print.sim_graph <- function(x, ...) {
  cat(
    "<sim_graph>",
    sprintf(
      "  %d covariate(s): %s",
      length(x$covariates),
      paste(names(x$covariates), collapse = ", ")
    ),
    sprintf(
      "  %d process(es): %s",
      length(x$processes),
      paste(names(x$processes), collapse = ", ")
    ),
    sprintf("  %d effect(s)", length(x$effects)),
    sep = "\n"
  )
  invisible(x)
}

# A "transient" process is at risk only while its own count is still below
# its limit (always true for the default limit = Inf); censoring's at-risk
# indicator is scaled by `cens`; terminal processes are always at risk.
# Returns a function of `event_counts` (a named list, one entry per process,
# each a vector of per-individual counts) to a process x individual at-risk
# matrix with process-named rows, for all individuals at once.
.sim_graph_at_risk <- function(graph, cens) {
  process_names <- names(graph$processes)
  types <- vapply(graph$processes, `[[`, character(1), "type")
  transient <- process_names[types == "transient"]
  limit <- vapply(graph$processes[transient], `[[`, numeric(1), "limit")
  censoring <- process_names[types == "censoring"]

  function(event_counts) {
    at_risk <- matrix(
      1,
      nrow = length(process_names),
      ncol = length(event_counts[[1]]),
      dimnames = list(process_names, NULL)
    )
    at_risk[censoring, ] <- cens
    for (nm in transient) {
      at_risk[nm, ] <- as.numeric(event_counts[[nm]] < limit[nm])
    }
    at_risk
  }
}

#' Simulate Event History Data from a `sim_graph()`
#'
#' `sim_event_graph` simulates multistate event history data from a
#' [sim_graph()] specification.
#'
#' @param graph A [sim_graph()].
#' @param n Integer. Number of individuals to simulate.
#' @param intervene Named list of interventions. A covariate name fixes that
#'   covariate to the given value for everyone; a process name multiplies
#'   that process's hazard by the given value.
#' @param cens Numeric. Multiplier on censoring hazards; `0` turns censoring
#'   off. Default 1.
#' @param max_cens Numeric. End of follow-up: anyone still followed is
#'   censored then, with `event = "max_cens"`. Default `Inf`.
#' @param max_events Integer. Maximum number of events per individual.
#'   Default 50.
#' @param lower,upper Numeric. Root-finding bounds, used when processes have
#'   different Weibull parameters. Defaults `1e-25`/`1e8`.
#' @param time_step Numeric. Grid step on which [sim_effect()]s using `t`
#'   are evaluated; ignored if none do. Smaller is more accurate but slower.
#'   Default `0.01`.
#' @param seed Integer. Random seed. Default `NULL` (no seed set).
#' @return A `data.table` with one row per event: `id`, `time`, `event`
#'   (factor naming the process, or `"max_cens"`), the covariates, and each
#'   `"transient"` process's number of events so far.
#'
#' @examples
#' # An illness-death graph: "age" is a plain covariate, "treated" is a
#' # second covariate whose generator depends on age, "illness" is a
#' # transient process capped at 2 events (limit = 2, e.g. two distinct
#' # relapse diagnoses) that can itself raise the death hazard, and "checkup"
#' # is an unlimited (limit = Inf) transient process.
#' graph <- sim_graph(
#'   age = sim_covariate(function(N) rnorm(N, mean = 50, sd = 10)),
#'   treated = sim_covariate(function(N, age) rbinom(N, 1, plogis(-2 + 0.03 * age))),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   illness = sim_process("transient", eta = 0.15, nu = 1.2, limit = 2),
#'   checkup = sim_process("transient", eta = 0.2, nu = 1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.03),
#'     sim_effect("treated", "death", coef = -0.5),
#'     sim_effect("illness", "death", coef = 1.2),
#'     sim_effect("checkup", "death", coef = 0.8)
#'   )
#' )
#' data <- sim_event_graph(graph, n = 100)
#' head(data)
#'
#' # illness has fired at most twice for everyone (limit = 2):
#' all(data$illness <= 2)
#'
#' # Double the censoring rate (cens scales every "censoring"-type process),
#' # halve the death hazard, and fix everyone's treatment status to 1:
#' data_intervened <- sim_event_graph(
#'   graph,
#'   n = 100,
#'   cens = 2,
#'   intervene = list(death = 0.5, treated = 1)
#' )
#' head(data_intervened)
#'
#' @seealso [sim_graph()], [event_risk()]
#' @export
sim_event_graph <- function(
  graph,
  n,
  intervene = list(),
  cens = 1,
  max_cens = Inf,
  max_events = 50,
  lower = 1e-25,
  upper = 1e8,
  time_step = 0.01,
  seed = NULL
) {
  checkmate::assert_class(graph, "sim_graph")
  checkmate::assert_count(n, positive = TRUE)
  checkmate::assert_int(seed, null.ok = TRUE)
  checkmate::assert_list(intervene, names = "unique")
  checkmate::assert_number(cens, finite = TRUE)
  checkmate::assert_number(time_step, lower = 0, finite = TRUE)
  if (time_step == 0) {
    stop("time_step must be positive.")
  }

  covariate_names <- names(graph$covariates)
  process_names <- names(graph$processes)

  unknown <- setdiff(names(intervene), c(covariate_names, process_names))
  if (length(unknown) > 0) {
    stop(
      "intervene targets unknown name(s) not in graph: ",
      paste(unknown, collapse = ", ")
    )
  }

  run <- function() {
    run_sim_graph(
      graph,
      n = n,
      intervene = intervene,
      cens = cens,
      max_cens = max_cens,
      max_events = max_events,
      lower = lower,
      upper = upper,
      time_step = time_step
    )
  }
  if (is.null(seed)) run() else withr::with_seed(seed, run())
}

# Approximates a coxph() fit's baseline cumulative hazard with a Weibull
# curve, by regressing log(cumulative hazard) on log(time) (a Weibull hazard
# is linear on that scale).
.sim_graph_weibull_from_fit <- function(fit) {
  bh <- survival::basehaz(fit, centered = FALSE)
  bh <- bh[bh$hazard > 0, ]
  fit_weibull <- stats::lm(log(hazard) ~ log(time), data = bh)
  c(
    eta = unname(exp(stats::coef(fit_weibull)[1])),
    nu = unname(stats::coef(fit_weibull)[2])
  )
}

# A sim_covariate() regenerating a plain (non-factor) column: Bernoulli(mean)
# if 0/1-valued, Normal(mean, sd) otherwise.
.sim_graph_covariate_from_column <- function(col) {
  if (all(col %in% c(0, 1))) {
    p <- mean(col)
    sim_covariate(local({
      force(p)
      function(N) stats::rbinom(N, 1, p)
    }))
  } else {
    mu <- mean(col)
    sigma <- stats::sd(col)
    sim_covariate(local({
      force(mu)
      force(sigma)
      function(N) stats::rnorm(N, mu, sigma)
    }))
  }
}

# A sim_covariate() regenerating a factor column from its observed level
# proportions. simEventData()'s simmatrix is a purely numeric matrix, so the
# draw uses integer level codes (1:nlevels, in levels(col) order) rather than
# the original character labels.
.sim_graph_covariate_from_factor <- function(col) {
  codes <- seq_along(levels(col))
  probs <- as.numeric(prop.table(table(col)))
  sim_covariate(local({
    force(codes)
    force(probs)
    function(N) sample(codes, N, replace = TRUE, prob = probs)
  }))
}

# A sim_derived() dummy for one non-reference factor level (level_code is
# that level's position in levels(col), matching
# .sim_graph_covariate_from_factor()'s integer coding), with its formal
# argument literally named `varname` (matching coxph()'s coefficient naming
# convention paste0(varname, level) for the default treatment contrasts), so
# .simEvent_draw_baseline()'s dependency detection works unmodified.
.sim_graph_level_dummy <- function(varname, level_code) {
  f <- function() NULL
  formals(f) <- stats::setNames(alist(x = ), varname)
  body(f) <- bquote(as.numeric(.(as.symbol(varname)) == .(level_code)))
  sim_derived(f)
}

#' Build a `sim_graph()` from Fitted Cox Models
#'
#' Builds a [sim_graph()] from one fitted [survival::coxph()] model per
#' process, so simulated data resembles the data they were fit to.
#'
#' Covariates are regenerated from `data`: numeric columns as Normal (or
#' Bernoulli if 0/1), factor columns from their observed proportions.
#' Categorical covariates must be factor columns, used as-is in the
#' `coxph()` formulas (not wrapped in `factor()`). Each process's Weibull
#' parameters are fit to its baseline cumulative hazard.
#'
#' A formula term naming another process (e.g. `relapse` in
#' `~ L0 + relapse`) becomes a [sim_effect()] from that process. Its
#' coefficient is only valid if that fit treated it as time-varying (e.g.
#' using [interval_format_data()]).
#'
#' @param fits Named list of [survival::coxph()] fits, one per process.
#' @param data The `data.frame` the fits were estimated from.
#' @param types Named character vector giving each process's
#'   [sim_process()] `type` (`"censoring"`, `"terminal"`, or `"transient"`),
#'   with the same names as `fits`.
#' @param limits Named list giving `limit` for any `"transient"` process not
#'   using the default (`limit = Inf`).
#'
#' @return A [sim_graph()], ready for [sim_event_graph()].
#' @seealso [sim_event_graph()]
#' @examples
#' library(survival)
#'
#' # Some "observed" data, from a 3-cause competing-risks sim_graph():
#' set.seed(1405)
#' observed_graph <- sim_graph(
#'   L0 = sim_covariate(function(N) runif(N)),
#'   A0 = sim_covariate(function(N, L0) rbinom(N, 1, plogis(-0.5 + L0))),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   cause1 = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   cause2 = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("L0", "censoring", 0.5),
#'     sim_effect("A0", "censoring", -1),
#'     sim_effect("L0", "cause1", -0.5),
#'     sim_effect("A0", "cause1", 0.5),
#'     sim_effect("A0", "cause2", 0.5)
#'   )
#' )
#' observed_data <- sim_event_graph(observed_graph, n = 1000)
#'
#' # Refit each process from that "observed" data, then rebuild a sim_graph()
#' # from the fits, as if observed_data came from an outside source and
#' # observed_graph were unknown:
#' fits <- list(
#'   censoring = coxph(
#'     Surv(time, event == "censoring") ~ L0 + A0,
#'     data = observed_data
#'   ),
#'   cause1 = coxph(Surv(time, event == "cause1") ~ L0 + A0, data = observed_data),
#'   cause2 = coxph(Surv(time, event == "cause2") ~ L0 + A0, data = observed_data)
#' )
#' types <- c(censoring = "censoring", cause1 = "terminal", cause2 = "terminal")
#'
#' graph <- sim_graph_from_fits(fits, observed_data, types)
#' new_data <- sim_event_graph(graph, n = 1000)
#' head(new_data)
#'
#' # Event-type distribution should be comparable between the observed and
#' # newly simulated data:
#' rbind(
#'   observed = prop.table(table(observed_data$event)),
#'   simulated = prop.table(table(new_data$event))
#' )
#' @export
sim_graph_from_fits <- function(fits, data, types, limits = list()) {
  checkmate::assert_list(fits, names = "unique", min.len = 1)
  if (!all(vapply(fits, inherits, logical(1), what = "coxph"))) {
    stop("Every entry of fits must be a survival::coxph() fit.")
  }
  checkmate::assert_data_frame(data)
  checkmate::assert_character(types, names = "unique")
  checkmate::assert_set_equal(names(fits), names(types))
  checkmate::assert_subset(
    types,
    c("censoring", "terminal", "transient")
  )
  checkmate::assert_list(limits, names = "unique")
  checkmate::assert_subset(names(limits), names(types)[types == "transient"])

  term_names <- unique(unlist(lapply(fits, function(fit) {
    attr(stats::terms(fit), "term.labels")
  })))
  # A term that names another process (rather than a data column) is a
  # cross-process effect e.g. coxph(Surv(...) ~ L0 + relapse), where
  # relapse is itself a simulated process's event count, not a baseline
  # covariate to regenerate.
  covariate_term_names <- setdiff(term_names, names(types))
  missing_cols <- setdiff(covariate_term_names, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "fits reference covariate(s) not found in data or in types (as a ",
      "cross-process effect): ",
      paste(missing_cols, collapse = ", "),
      ". Categorical covariates must be factor columns in data, ",
      "referenced directly in the coxph() formula (not wrapped in ",
      "factor() there)."
    )
  }

  # One sim_covariate() per raw covariate, plus one sim_derived() dummy per
  # non-reference level for factor covariates (dummy names double as the
  # coefficient names coxph() itself produces, e.g. "region2").
  baseline_nodes <- list()
  for (nm in covariate_term_names) {
    col <- data[[nm]]
    if (is.factor(col)) {
      lv <- levels(col)
      baseline_nodes[[nm]] <- .sim_graph_covariate_from_factor(col)
      for (i in seq_along(lv)[-1]) {
        baseline_nodes[[paste0(nm, lv[i])]] <- .sim_graph_level_dummy(nm, i)
      }
    } else {
      baseline_nodes[[nm]] <- .sim_graph_covariate_from_column(col)
    }
  }

  process_nodes <- list()
  effects <- list()
  for (proc in names(fits)) {
    fit <- fits[[proc]]
    weibull <- .sim_graph_weibull_from_fit(fit)
    process_nodes[[proc]] <- sim_process(
      type = types[[proc]],
      eta = weibull["eta"],
      nu = weibull["nu"],
      limit = if (is.null(limits[[proc]])) Inf else limits[[proc]]
    )

    cf <- stats::coef(fit)
    for (v in names(cf)) {
      effects[[length(effects) + 1]] <- sim_effect(v, proc, unname(cf[[v]]))
    }
  }

  do.call(
    sim_graph,
    c(baseline_nodes, process_nodes, list(effects = effects))
  )
}
