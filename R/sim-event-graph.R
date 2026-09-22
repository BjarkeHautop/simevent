#----------------------------------------------------------------------
## A graph-based front-end to the simEventData() engine.
#----------------------------------------------------------------------

#' Define a Baseline Covariate for `sim_graph()`
#'
#' @param generator Function generating the covariate. Takes `N` and,
#'   optionally, any subset of the names of other covariates defined earlier
#'   in the same [sim_graph()] call, matched by argument name.
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
#' @param fn Function of one or more covariates defined earlier in the same
#'   [sim_graph()] call, matched by argument name.
#'
#' @return An object of class `sim_derived`, for use in [sim_graph()].
#' @seealso [sim_graph()], [sim_covariate()], [sim_effect()]
#' @examples
#' # A categorical covariate's per-level dummy:
#' sim_derived(function(region) as.numeric(region == 2))
#'
#' # An interaction between two covariates:
#' sim_derived(function(L0, A0) L0 * A0)
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
#' @param type What kind of process this is, and in particular whether it
#'   ends an individual's follow-up:
#'   \describe{
#'     \item{`"censoring"`}{Right-censoring: ends follow-up, but isn't an
#'       outcome event. At most one per individual.}
#'     \item{`"terminal"`}{An absorbing outcome event (e.g. death, or one
#'       cause in a competing-risks setting): ends follow-up. At most one
#'       per individual.}
#'     \item{`"transient"`}{Doesn't end follow-up, and can fire more than
#'       once (up to `limit` times, default unlimited). Because follow-up
#'       continues, its running event count can itself be used as a
#'       time-varying [sim_effect()] `from` for other processes (e.g. a
#'       relapse process raising the hazard of a later terminal event).}
#'   }
#' @param eta Numeric. Weibull shape parameter of the process's baseline
#'   intensity.
#' @param nu Numeric. Weibull scale parameter of the process's baseline
#'   intensity.
#' @param limit Integer, or `Inf`. For `type = "transient"` only: the maximum
#'   number of times this process can fire. Default `Inf` (unlimited,
#'   i.e. recurrent); `limit = 1` gives a "one-jump" process (at most a
#'   single event). Ignored for other types.
#'
#' @return An object of class `sim_process`, for use in [sim_graph()].
#' @seealso [sim_graph()], [sim_covariate()]
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
#' An effect is a directed, weighted edge from a baseline covariate or
#' process to a process's intensity: multiplying that process's baseline
#' hazard by `exp(coef)` while `from` is "active" (its drawn value for a
#' covariate, or its current event count for a process). For an effect that
#' isn't linear in an existing covariate (a categorical level, an
#' interaction, a threshold), define a [sim_derived()] covariate for it first
#' and point `from` at that.
#'
#' @param from Character. Name of a covariate, [sim_derived()] covariate, or
#'   process defined in the same [sim_graph()] call.
#' @param to Character. Name of a process defined in the same [sim_graph()]
#'   call.
#' @param coef Numeric. Cox-type coefficient.
#'
#' @return An object of class `sim_effect`, for use in [sim_graph()].
#' @seealso [sim_graph()]
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
#'   objects. Every name must be unique across all three. A [sim_derived()]
#'   covariate's dependencies must each name an earlier
#'   [sim_covariate()]/[sim_derived()] in the same call.
#' @param effects List of [sim_effect()] objects between nodes named in
#'   `...`.
#'
#' @return An object of class `sim_graph`.
#' @seealso [sim_event_graph()], [sim_covariate()], [sim_derived()],
#'   [sim_process()], [sim_effect()]
#' @examples
#' graph <- sim_graph(
#'   age = sim_covariate(function(N) rnorm(N)),
#'   age_sq = sim_derived(function(age) age^2),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.5),
#'     sim_effect("age_sq", "death", coef = -0.05)
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

  baseline_names <- names(nodes)[is_baseline]
  for (nm in baseline_names) {
    node <- nodes[[nm]]
    if (inherits(node, "sim_derived")) {
      earlier <- baseline_names[seq_len(match(nm, baseline_names) - 1)]
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
  for (eff in effects) {
    if (!(eff$from %in% names(nodes))) {
      stop("sim_effect() 'from' not found in graph: '", eff$from, "'")
    }
    if (!(eff$to %in% process_names)) {
      stop(
        "sim_effect() 'to' must name a sim_process() in the graph; '",
        eff$to,
        "' is not one."
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

# Censoring first, then terminal, then transient in declared order. Only the
# relative grouping matters (for term_deltas); the exact tie-break order
# within a group is otherwise arbitrary but must agree everywhere
# eta/nu/beta/term_deltas are built from it.
.sim_graph_process_order <- function(graph) {
  types <- vapply(graph$processes, `[[`, character(1), "type")
  nm <- names(graph$processes)
  c(
    nm[types == "censoring"],
    nm[types == "terminal"],
    nm[!(types %in% c("censoring", "terminal"))]
  )
}

# A "transient" process is at risk only while its own count is still below
# its limit (always true for the default limit = Inf); censoring's at-risk
# indicator is scaled by `cens`; terminal processes are always at risk.
.sim_graph_at_risk <- function(graph, process_order, cens) {
  types <- stats::setNames(
    vapply(graph$processes[process_order], `[[`, character(1), "type"),
    process_order
  )
  transient <- process_order[types == "transient"]
  limit <- vapply(graph$processes[transient], `[[`, numeric(1), "limit")
  names(limit) <- transient
  censoring <- process_order[types == "censoring"]

  function(events) {
    at_risk <- stats::setNames(rep(1, length(process_order)), process_order)
    at_risk[censoring] <- cens
    at_risk[transient] <- as.numeric(events[transient] < limit[transient])
    at_risk
  }
}

#' Simulate Event History Data from a `sim_graph()`
#'
#' `sim_event_graph` simulates multistate event history data from a
#' [sim_graph()] specification, via the same underlying sampler as
#' [simEventData()].
#'
#' @param graph A [sim_graph()].
#' @param n Integer. Number of individuals to simulate.
#' @param intervene Named list implementing a `do()`-style intervention on
#'   `graph`, for simulating counterfactual data without redefining the whole
#'    graph. Keyed by a covariate or process name from `graph`:
#'   \describe{
#'     \item{Covariate name}{Overrides that [sim_covariate()]/
#'       [sim_derived()]'s draw, fixing it to the given constant for every
#'       individual instead of generating/deriving it.}
#'     \item{Process name}{Multiplies that process's baseline `eta`,
#'       scaling its hazard for everyone (e.g. `0.5` halves it, `2` doubles
#'       it).}
#'   }
#' @param cens Numeric. At-risk indicator scaling for `"censoring"`-type
#'   processes. Default 1.
#' @param max_cens Numeric. Maximum censoring time. Default `Inf`.
#' @param max_events Integer. Maximum number of events simulated per
#'   individual before an error is raised. Default 50.
#' @param lower,upper Numeric. Root-finding bounds for the inverse cumulative
#'   hazard, used only when processes don't all share the same Weibull
#'   shape/scale. Defaults `1e-25`/`1e8`.
#'
#' @return A `data.table` with columns `id`, `time`, `delta` (the 0-indexed
#'   position of the firing process in `graph`'s process order: censoring
#'   processes first, then terminal, then the rest in declared order), the
#'   graph's covariates, and one column per non-terminal, non-censoring
#'   process (its cumulative event count).
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
#' @seealso [sim_graph()], [simEventData()], [sim.generic()]
#' @export
sim_event_graph <- function(
  graph,
  n,
  intervene = list(),
  cens = 1,
  max_cens = Inf,
  max_events = 50,
  lower = 1e-25,
  upper = 1e8
) {
  checkmate::assert_class(graph, "sim_graph")
  checkmate::assert_count(n, positive = TRUE)
  checkmate::assert_list(intervene, names = "unique")
  checkmate::assert_number(cens, finite = TRUE)

  covariate_names <- names(graph$covariates)
  process_order <- .sim_graph_process_order(graph)

  unknown <- setdiff(names(intervene), c(covariate_names, process_order))
  if (length(unknown) > 0) {
    stop(
      "intervene targets unknown name(s) not in graph: ",
      paste(unknown, collapse = ", ")
    )
  }

  run_sim_graph(
    graph,
    n = n,
    intervene = intervene,
    cens = cens,
    max_cens = max_cens,
    max_events = max_events,
    lower = lower,
    upper = upper
  )
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
#' `sim_graph_from_fits` builds a [sim_graph()] automatically from a set of
#' fitted [survival::coxph()] models (one per process) and the data they
#' were fit to, so simulated data mimics an observed dataset's distribution.
#'
#' Baseline covariates are regenerated from `data`'s own columns: numeric
#' columns as Normal(mean, sd) (or Bernoulli(mean) if the column is 0/1
#' valued), and factor columns as a categorical draw from their observed
#' proportions, with one [sim_derived()] dummy per non-reference level,
#' matching how [survival::coxph()]'s default treatment contrasts name
#' coefficients (`"<variable><level>"`). Categorical covariates must
#' therefore be factor columns in `data`, referenced directly in each
#' `coxph()` formula (not wrapped in `factor()` there).
#'
#' Each process's Weibull `eta`/`nu` is approximated from its `coxph()`
#' fit's baseline cumulative hazard.
#'
#' A `coxph()` term that names another process in `fits`/`types` (rather
#' than a column of `data`) is a cross-process effect -- e.g.
#' `coxph(Surv(...) ~ L0 + relapse)`, where `relapse` is itself one of the
#' processes being modeled -- and is wired as a [sim_effect()] from that
#' process directly, not regenerated as a (meaningless, since its true
#' value evolves over follow-up rather than being fixed at baseline)
#' covariate. Note that such a term must itself have been fit as a properly
#' time-varying covariate (e.g. via `coxph()` on tstart-tstop data built
#' with [IntFormatData()]) for its coefficient to be a valid estimate in
#' the first place; `sim_graph_from_fits()` only wires whatever coefficient
#' `fits` already contains, it does not check how that fit was estimated.
#'
#' @param fits Named list of [survival::coxph()] fits, one per process,
#'   named after the process. Every process referenced as a covariate in
#'   any fit's formula (a cross-process effect) must also have its own
#'   entry here.
#' @param data The `data.frame` the fits were estimated from; must contain
#'   every covariate referenced in `fits` that isn't itself one of `fits`'
#'   processes.
#' @param types Named character vector giving each process's
#'   [sim_process()] `type` (`"censoring"`, `"terminal"`, or `"transient"`),
#'   with the same names as `fits`.
#' @param limits Named list giving `limit` for any `"transient"` process not
#'   using the default (`limit = Inf`).
#'
#' @return A [sim_graph()], ready for [sim_event_graph()].
#' @seealso [sim_event_graph()], [sim.from.data()]
#' @examples
#' library(survival)
#'
#' # Some "observed" data, from a 3-cause competing-risks sim_graph():
#' set.seed(1405)
#' observed_graph <- sim_graph(
#'   L0 = sim_covariate(function(N) runif(N)),
#'   A0 = sim_covariate(function(N, L0) rbinom(N, 1, 0.5)),
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
#'   censoring = coxph(Surv(time, delta == 0) ~ L0 + A0, data = observed_data),
#'   cause1 = coxph(Surv(time, delta == 1) ~ L0 + A0, data = observed_data),
#'   cause2 = coxph(Surv(time, delta == 2) ~ L0 + A0, data = observed_data)
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
#'   observed = prop.table(table(observed_data$delta)),
#'   simulated = prop.table(table(new_data$delta))
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
