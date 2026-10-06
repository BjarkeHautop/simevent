#----------------------------------------------------------------------
## The simulation API: node/edge constructors, sim_model(),
## sim_events() and sim_model_from_fits(). The engine itself lives in
## sim-engine.R.
#----------------------------------------------------------------------

#' Define a Baseline Covariate for `sim_model()`
#'
#' @param generator Function of `N` (number of individuals) returning the
#'   covariate's values. May also take covariates defined earlier in the same
#'   [sim_model()] call, by name.
#'
#' @return An object of class `sim_covariate`, for use in [sim_model()].
#' @seealso [sim_model()], [sim_process()]
#' @examples
#' # A covariate that doesn't depend on any other:
#' sim_covariate(function(N) rnorm(N, mean = 50, sd = 10))
#'
#' # A covariate whose generator depends on another covariate defined
#' # earlier in the same sim_model() call:
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

#' Define a Derived Covariate for `sim_model()`
#'
#' `sim_derived` builds a covariate that is a deterministic transform of one
#' or more other covariates defined earlier in the same [sim_model()] call.
#'
#' @param fn Function of covariates defined earlier in the same
#'   [sim_model()] call, by name.
#'
#' @return An object of class `sim_derived`, for use in [sim_model()].
#' @seealso [sim_model()], [sim_covariate()], [sim_effect()]
#' @examples
#' # BMI from weight (kg) and height (m), stored as its own column and usable
#' # by covariates defined after it:
#' model <- sim_model(
#'   weight = sim_covariate(function(N) rnorm(N, mean = 80, sd = 12)),
#'   height = sim_covariate(function(N) rnorm(N, mean = 1.75, sd = 0.08)),
#'   bmi = sim_derived(function(weight, height) weight / height^2),
#'   statin = sim_covariate(function(N, bmi) rbinom(N, 1, plogis(-5 + 0.15 * bmi))),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(sim_effect("statin", "death", coef = -0.3))
#' )
#' head(sim_events(model, n = 5))
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
.sim_wrap_derived <- function(fn) {
  wrapper <- function() {}
  formals(wrapper) <- c(alist(N = ), formals(fn))
  body(wrapper) <- as.call(c(quote(fn), lapply(names(formals(fn)), as.symbol)))
  environment(wrapper) <- list2env(list(fn = fn), parent = environment(fn))
  wrapper
}

#' Define a Time-Varying Covariate for `sim_model()`
#'
#' `sim_marker` builds a covariate, such as a lab value measured at visits,
#' that is drawn at baseline and redrawn whenever one of the `update`
#' processes fires. It stays constant between those events. In [sim_events()]
#' output, each row holds its value after that row's event.
#'
#' @param init Function of `N` giving the initial values, as for
#'   [sim_covariate()]. Covariates defined after the marker see its initial
#'   value.
#' @param update Character. Names of the `"transient"` [sim_process()]es
#'   whose events redraw the marker.
#' @param draw Function returning the new values. It may take, by name:
#'   `N` (number of individuals updated), `t` (the event time), any
#'   covariate or marker (current value, including this marker's own), and
#'   any process (number of events so far, including the triggering event).
#'
#' @return An object of class `sim_marker`, for use in [sim_model()].
#' @seealso [sim_model()], [sim_covariate()]
#' @examples
#' # Blood pressure measured at each visit, lowered by treatment and driving
#' # both treatment initiation and stroke:
#' model <- sim_model(
#'   age = sim_covariate(function(N) rnorm(N, mean = 60, sd = 10)),
#'   visit = sim_process("transient", eta = 1, nu = 1),
#'   bp = sim_marker(
#'     init = function(N, age) rnorm(N, 130 + 0.5 * (age - 60), 12),
#'     update = "visit",
#'     draw = function(N, bp, treatment) {
#'       rnorm(N, 0.8 * bp + 26 - 2 * treatment, 6)
#'     }
#'   ),
#'   treatment = sim_process("transient", eta = 0.05, nu = 1, limit = 1),
#'   stroke = sim_process("terminal", eta = 0.01, nu = 1.2),
#'   effects = list(
#'     sim_effect("bp - 130", "treatment", coef = 0.08),
#'     sim_effect("bp - 130", "stroke", coef = 0.03),
#'     sim_effect("treatment", "stroke", coef = -0.2)
#'   )
#' )
#' head(sim_events(model, n = 5, max_cens = 5), 10)
#' @export
sim_marker <- function(init, update, draw) {
  checkmate::assert_function(init)
  if (!("N" %in% names(formals(init)))) {
    stop(
      "sim_marker()'s init must have a formal argument named 'N' ",
      "(the number of individuals to simulate); got formal argument(s): ",
      paste(names(formals(init)), collapse = ", ")
    )
  }
  checkmate::assert_character(
    update,
    min.len = 1,
    any.missing = FALSE,
    unique = TRUE
  )
  checkmate::assert_function(draw)
  structure(
    list(generator = init, update = update, draw = draw),
    class = "sim_marker"
  )
}

#' Define an Event Process for `sim_model()`
#'
#' `sim_process` builds an event process whose baseline intensity is Weibull,
#' \deqn{\lambda_0(t) = \eta \nu t^{\nu - 1},}
#' i.e. cumulative baseline hazard \eqn{\eta t^\nu}, or follows a given
#' cumulative baseline hazard curve (`cumhaz`). [sim_effect()]s into the
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
#' @param cumhaz Optional `data.frame` with columns `time` and `hazard`
#'   giving the cumulative baseline hazard, e.g. from
#'   [survival::basehaz()] with `centered = FALSE`. Used instead of `eta` and
#'   `nu`, and interpolated linearly. The hazard is unknown after the last
#'   `time`, so [sim_events()] ends follow-up there, as for `max_cens`.
#'
#' @return An object of class `sim_process`, for use in [sim_model()].
#' @seealso [sim_model()], [sim_covariate()]
#' @examples
#' # Death, with a slowly increasing hazard:
#' sim_process("terminal", eta = 0.1, nu = 1.1)
#'
#' # A relapse process that can fire at most twice:
#' sim_process("transient", eta = 0.2, nu = 1, limit = 2)
#'
#' # A hazard that is high early on and low later:
#' sim_process(
#'   "terminal",
#'   cumhaz = data.frame(time = c(1, 5), hazard = c(0.5, 0.7))
#' )
#' @export
sim_process <- function(
  type = c("censoring", "terminal", "transient"),
  eta,
  nu,
  limit = Inf,
  cumhaz = NULL
) {
  type <- match.arg(type)
  checkmate::assert(
    checkmate::check_count(limit, positive = TRUE),
    checkmate::check_choice(limit, Inf)
  )
  if (is.null(cumhaz)) {
    checkmate::assert_number(eta, lower = 0, finite = TRUE)
    checkmate::assert_number(nu, lower = 0, finite = TRUE)
  } else {
    if (!missing(eta) || !missing(nu)) {
      stop("sim_process() takes either eta and nu, or cumhaz, not both.")
    }
    cumhaz <- .sim_check_cumhaz(cumhaz)
    eta <- NA_real_
    nu <- NA_real_
  }
  structure(
    list(type = type, eta = eta, nu = nu, limit = limit, cumhaz = cumhaz),
    class = "sim_process"
  )
}

# Validates a sim_process() `cumhaz` and returns its time/hazard columns,
# without any time-0 row (the cumulative hazard is 0 there by definition).
.sim_check_cumhaz <- function(cumhaz) {
  checkmate::assert_data_frame(cumhaz, min.rows = 1)
  checkmate::assert_names(names(cumhaz), must.include = c("time", "hazard"))
  time <- cumhaz$time
  hazard <- cumhaz$hazard
  checkmate::assert_numeric(time, lower = 0, finite = TRUE, any.missing = FALSE)
  checkmate::assert_numeric(
    hazard,
    lower = 0,
    finite = TRUE,
    any.missing = FALSE
  )
  if (is.unsorted(time, strictly = TRUE)) {
    stop("sim_process()'s cumhaz$time must be strictly increasing.")
  }
  if (is.unsorted(hazard)) {
    stop("sim_process()'s cumhaz$hazard must be non-decreasing.")
  }
  if (time[1] == 0) {
    if (hazard[1] != 0) {
      stop("sim_process()'s cumhaz$hazard must be 0 at time 0.")
    }
    time <- time[-1]
    hazard <- hazard[-1]
  }
  if (length(time) == 0 || hazard[length(hazard)] == 0) {
    stop("sim_process()'s cumhaz$hazard must eventually be positive.")
  }
  data.frame(time = time, hazard = hazard)
}

#' Define an Effect for `sim_model()`
#'
#' Multiplies the hazard of process `to` by `exp(coef * from)`.
#'
#' @param from Character. A covariate name (its value), a process name (its
#'   number of events so far), or an R expression of these. Expressions may
#'   also use:
#'   \describe{
#'     \item{`t`}{The current time (see [sim_events()]'s `time_step`).}
#'     \item{`T_<proc>.<k>`}{Time of `proc`'s `k`-th event, `0` if it
#'       hasn't happened yet, e.g. `T_operation.1`. Multiply by the event
#'       count, as in `operation * f(t - T_operation.1)`, so the effect only
#'       applies once the event has happened.}
#'     \item{`last_time(proc)`}{Time of `proc`'s latest event, `-Inf` if
#'       none.}
#'   }
#' @param to Character. Name of the affected process.
#' @param coef Numeric. Cox-type coefficient.
#'
#' @return An object of class `sim_effect`, for use in [sim_model()].
#' @seealso [sim_model()]
#' @examples
#' sim_effect("age", "death", coef = 0.03)
#' sim_effect("(age - 60)^2", "death", coef = 0.001)
#' sim_effect("relapse == 3", "death", coef = 1.2)
#' sim_effect("t - last_time(checkup) < 1", "death", coef = 0.5)
#' sim_effect("operation * (t - T_operation.1)", "death", coef = 0.1)
#' sim_effect("operation * exp(-(t - T_operation.1))", "death", coef = 2)
#' @export
sim_effect <- function(from, to, coef) {
  checkmate::assert_string(from)
  checkmate::assert_string(to)
  checkmate::assert_number(coef, finite = TRUE)
  structure(list(from = from, to = to, coef = coef), class = "sim_effect")
}

#' Build a Simulation Model for `sim_events()`
#'
#' `sim_model` assembles a set of named [sim_covariate()]/[sim_derived()]/
#' [sim_marker()]/[sim_process()] nodes and [sim_effect()] edges between them into a single
#' specification, which [sim_events()] can then simulate from.
#'
#' @param ... Named [sim_covariate()]/[sim_derived()]/[sim_marker()]/
#'   [sim_process()] objects. A covariate may only depend on covariates listed before it.
#' @param effects List of [sim_effect()]s.
#'
#' @return An object of class `sim_model`.
#' @seealso [sim_events()], [sim_covariate()], [sim_derived()],
#'   [sim_marker()], [sim_process()], [sim_effect()]
#' @examples
#' model <- sim_model(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect("age", "death", coef = 0.03),
#'     sim_effect("(age - 60)^2", "death", coef = 0.001)
#'   )
#' )
#' model
#' @export
sim_model <- function(..., effects = list()) {
  nodes <- list(...)
  checkmate::assert_list(nodes, names = "unique", min.len = 1)

  is_baseline <- vapply(
    nodes,
    inherits,
    logical(1),
    what = c("sim_covariate", "sim_derived", "sim_marker")
  )
  is_process <- vapply(nodes, inherits, logical(1), what = "sim_process")
  if (!all(is_baseline | is_process)) {
    stop(
      "All named arguments to sim_model() must be sim_covariate(), ",
      "sim_derived(), sim_marker(), or sim_process() objects; offending ",
      "name(s): ",
      paste(names(nodes)[!(is_baseline | is_process)], collapse = ", ")
    )
  }
  if (!any(is_process)) {
    stop("sim_model() needs at least one sim_process().")
  }

  # Names that would collide with sim_events()'s output columns, with
  # the non-process labels its `event` column can take, or with the
  # variables available inside a sim_effect() expression.
  reserved_names <- c(
    "id",
    "time",
    "event",
    "max_cens",
    "none",
    "t",
    "last_time"
  )
  reserved <- intersect(names(nodes), reserved_names)
  if (length(reserved) > 0) {
    stop(
      "sim_model() node name(s) are reserved: ",
      paste(reserved, collapse = ", "),
      ". Reserved names are ",
      paste(reserved_names, collapse = ", "),
      "."
    )
  }
  process_names <- names(nodes)[is_process]
  clash <- .sim_history_vars(names(nodes), process_names)$name
  if (length(clash) > 0) {
    stop(
      "sim_model() node name(s) clash with event-time variables: ",
      paste(clash, collapse = ", "),
      "."
    )
  }
  process_types <- vapply(nodes[is_process], `[[`, character(1), "type")
  if (!any(process_types == "terminal")) {
    stop(
      "sim_model() needs at least one sim_process(\"terminal\"): without ",
      "one, follow-up never ends."
    )
  }

  baseline_names <- names(nodes)[is_baseline]
  for (nm in baseline_names) {
    node <- nodes[[nm]]
    earlier <- baseline_names[seq_len(match(nm, baseline_names) - 1)]
    if (inherits(node, c("sim_covariate", "sim_marker"))) {
      missing <- setdiff(names(formals(node$generator)), c("N", earlier))
      if (length(missing) > 0) {
        stop(
          class(node)[1],
          "() '",
          nm,
          "' has argument(s) '",
          paste(missing, collapse = ", "),
          "' that do not name an earlier sim_covariate()/sim_derived()/",
          "sim_marker() in the same sim_model() call."
        )
      }
    }
    if (inherits(node, "sim_marker")) {
      transient <- process_names[process_types == "transient"]
      bad_update <- setdiff(node$update, transient)
      if (length(bad_update) > 0) {
        stop(
          "sim_marker() '",
          nm,
          "' has update '",
          paste(bad_update, collapse = ", "),
          "', which must name \"transient\" sim_process()es in the model."
        )
      }
      missing <- setdiff(names(formals(node$draw)), c("N", "t", names(nodes)))
      if (length(missing) > 0) {
        stop(
          "sim_marker() '",
          nm,
          "' has draw argument(s) '",
          paste(missing, collapse = ", "),
          "' that are not N, t, or a node in the same sim_model() call."
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
          "the same sim_model() call."
        )
      }
    }
  }

  checkmate::assert_list(effects, types = "sim_effect")
  effect_keys <- vapply(
    effects,
    function(eff) paste(eff$from, eff$to, sep = " -> "),
    character(1)
  )
  if (anyDuplicated(effect_keys) > 0) {
    stop(
      "sim_model() has duplicate sim_effect()s: ",
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
      # variables are all covariate/process names, `t` or T_<proc>.<k>;
      # last_time() takes a process name as an unevaluated argument, which
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
      history <- .sim_history_vars(used, process_names)
      unknown <- setdiff(used, c(names(nodes), history$name))
      if (length(unknown) > 0) {
        stop(
          "sim_effect() 'from' expression '",
          eff$from,
          "' references name(s) not found in model: ",
          paste(unknown, collapse = ", ")
        )
      }
      limit <- vapply(
        nodes[history$proc],
        function(node) if (node$type == "transient") node$limit else 1,
        numeric(1)
      )
      unreachable <- history$name[history$k > limit]
      if (length(unreachable) > 0) {
        stop(
          "sim_effect() 'from' expression '",
          eff$from,
          "' uses ",
          paste(unreachable, collapse = ", "),
          ", beyond the process's limit, so always 0."
        )
      }
      eff$parsed_from <- parsed
      effects[[i]] <- eff
    }
    if (!(eff$to %in% process_names)) {
      stop(
        "sim_effect() 'to' must name a sim_process() in the model; '",
        eff$to,
        "' is not one."
      )
    }
    sources <- if (eff$from %in% names(nodes)) {
      eff$from
    } else {
      used <- setdiff(all.vars(eff$parsed_from), "t")
      history <- .sim_history_vars(used, process_names)
      c(setdiff(used, history$name), history$proc)
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
    class = "sim_model"
  )
}

# The T_<proc>.<k> event-time variables among `vars`, as a data.frame with
# columns name, proc and k. Process names may themselves contain "." or "_".
.sim_history_vars <- function(vars, process_names) {
  pattern <- "^T_(.+)\\.([1-9][0-9]*)$"
  vars <- vars[grepl(pattern, vars)]
  proc <- sub(pattern, "\\1", vars)
  keep <- proc %in% process_names
  data.frame(
    name = vars[keep],
    proc = proc[keep],
    k = as.integer(sub(pattern, "\\2", vars[keep]))
  )
}

#' @export
print.sim_model <- function(x, ...) {
  covariate_names <- names(x$covariates)
  covariate_names <- covariate_names[!.sim_hidden(covariate_names)]
  cat(
    "<sim_model>",
    sprintf(
      "  %d covariate(s): %s",
      length(covariate_names),
      paste(covariate_names, collapse = ", ")
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
.sim_at_risk <- function(model, cens) {
  process_names <- names(model$processes)
  types <- vapply(model$processes, `[[`, character(1), "type")
  transient <- process_names[types == "transient"]
  limit <- vapply(model$processes[transient], `[[`, numeric(1), "limit")
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

#' Simulate Event History Data from a `sim_model()`
#'
#' `sim_events` simulates multistate event history data from a
#' [sim_model()] specification.
#'
#' @param model A [sim_model()].
#' @param n Integer. Number of individuals to simulate.
#' @param intervene Named list of interventions. A covariate or marker name
#'   fixes it to the given value for everyone, for all time; a process name
#'   multiplies that process's hazard by the given value.
#' @param cens Numeric. Multiplier on censoring hazards; `0` turns censoring
#'   off. Default 1.
#' @param max_cens Numeric. End of follow-up: anyone still followed is
#'   censored then, with `event = "max_cens"`. Default `Inf`. Follow-up also
#'   ends at the last `time` of any [sim_process()] `cumhaz` curve.
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
#' # An illness-death model: "age" is a plain covariate, "treated" is a
#' # second covariate whose generator depends on age, "illness" is a
#' # transient process capped at 2 events (limit = 2, e.g. two distinct
#' # relapse diagnoses) that can itself raise the death hazard, and "checkup"
#' # is an unlimited (limit = Inf) transient process.
#' model <- sim_model(
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
#' data <- sim_events(model, n = 100)
#' head(data)
#'
#' # illness has fired at most twice for everyone (limit = 2):
#' all(data$illness <= 2)
#'
#' # Double the censoring rate (cens scales every "censoring"-type process),
#' # halve the death hazard, and fix everyone's treatment status to 1:
#' data_intervened <- sim_events(
#'   model,
#'   n = 100,
#'   cens = 2,
#'   intervene = list(death = 0.5, treated = 1)
#' )
#' head(data_intervened)
#'
#' @seealso [sim_model()], [event_risk()]
#' @export
sim_events <- function(
  model,
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
  checkmate::assert_class(model, "sim_model")
  checkmate::assert_count(n, positive = TRUE)
  checkmate::assert_int(seed, null.ok = TRUE)
  checkmate::assert_list(intervene, names = "unique")
  checkmate::assert_number(cens, finite = TRUE)
  checkmate::assert_number(time_step, lower = 0, finite = TRUE)
  if (time_step == 0) {
    stop("time_step must be positive.")
  }

  covariate_names <- names(model$covariates)
  process_names <- names(model$processes)

  unknown <- setdiff(names(intervene), c(covariate_names, process_names))
  if (length(unknown) > 0) {
    stop(
      "intervene targets unknown name(s) not in model: ",
      paste(unknown, collapse = ", ")
    )
  }

  run <- function() {
    run_sim(
      model,
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

# A coxph() fit's cumulative baseline hazard at covariates 0.
.sim_basehaz <- function(fit, proc) {
  # centered = FALSE gives the hazard at covariates 0, so survfit()'s warning
  # about interactions and centering at the column means doesn't apply.
  bh <- withCallingHandlers(
    survival::basehaz(fit, centered = FALSE),
    warning = function(w) {
      if (grepl("interactions", conditionMessage(w), fixed = TRUE)) {
        invokeRestart("muffleWarning")
      }
    }
  )
  if ("strata" %in% names(bh)) {
    stop(
      "fits$",
      proc,
      " is stratified, which sim_model_from_fits() can't use."
    )
  }
  if (max(bh$hazard) == 0) {
    stop("fits$", proc, " has no events.")
  }
  bh[, c("time", "hazard")]
}

# Name of the hidden covariate sim_model_from_fits() resamples observed rows
# through. Covariates whose names start with "." are left out of
# sim_events()'s output and print()/summary().
.sim_row_name <- ".row"

.sim_hidden <- function(nms) startsWith(as.character(nms), ".")

# A sim_derived() looking up `values` at the resampled row index, so all of
# an individual's covariates come from the same observed row.
.sim_resampled_column <- function(values) {
  f <- function() NULL
  formals(f) <- stats::setNames(alist(x = ), .sim_row_name)
  body(f) <- bquote(values[.(as.symbol(.sim_row_name))])
  environment(f) <- list2env(list(values = values), parent = baseenv())
  sim_derived(f)
}

# A sim_derived() dummy for one non-reference factor level (level_code is
# that level's position in levels(col), since a factor column is
# regenerated as its integer codes), with its formal argument literally
# named `varname` (matching coxph()'s coefficient naming convention
# paste0(varname, level) for the default treatment contrasts), so
# .simEvent_draw_baseline()'s dependency detection works unmodified.
.sim_level_dummy <- function(varname, level_code) {
  f <- function() NULL
  formals(f) <- stats::setNames(alist(x = ), varname)
  body(f) <- bquote(as.numeric(.(as.symbol(varname)) == .(level_code)))
  sim_derived(f)
}

# The sim_effect() `from` for a coxph() coefficient name: a node name as-is,
# otherwise an expression, with interaction terms' ":" turned into "*".
.sim_effect_from_coef <- function(coef_name, node_names) {
  if (coef_name %in% node_names) {
    return(coef_name)
  }
  gsub(":", " * ", coef_name, fixed = TRUE)
}

#' Build a `sim_model()` from Fitted Cox Models
#'
#' Builds a [sim_model()] from one fitted [survival::coxph()] model per
#' process, so simulated data resembles the data they were fit to.
#'
#' Covariates are regenerated by resampling whole rows of `data`, so each
#' covariate keeps its observed distribution and its relationship to the
#' others. Categorical covariates must be factor columns, used as-is in the
#' `coxph()` formulas (not wrapped in `factor()`), and are regenerated as
#' their integer level codes. Formula terms may transform or interact
#' covariates (e.g. `I(age^2)`, `L0:A0`). Each process uses its fit's
#' cumulative baseline hazard as its [sim_process()] `cumhaz`, so simulated
#' follow-up ends at the last time in `data`.
#'
#' A formula term naming another process (e.g. `relapse` in
#' `~ L0 + relapse`) becomes a [sim_effect()] from that process. Its
#' coefficient is only valid if that fit treated it as time-varying (e.g.
#' using [interval_format_data()]).
#'
#' @param fits Named list of [survival::coxph()] fits, one per process.
#' @param data The `data.frame` the fits were estimated from. If it has an
#'   `id` column (e.g. from [sim_events()] or [interval_format_data()]),
#'   covariates are resampled from each id's first row.
#' @param types Named character vector giving each process's
#'   [sim_process()] `type` (`"censoring"`, `"terminal"`, or `"transient"`),
#'   with the same names as `fits`.
#' @param limits Named list giving `limit` for any `"transient"` process not
#'   using the default (`limit = Inf`).
#'
#' @return A [sim_model()], ready for [sim_events()].
#' @seealso [sim_events()]
#' @examples
#' library(survival)
#'
#' # Some "observed" data, from a 3-cause competing-risks sim_model():
#' set.seed(1405)
#' observed_model <- sim_model(
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
#' observed_data <- sim_events(observed_model, n = 1000)
#'
#' # Refit each process from that "observed" data, then rebuild a sim_model()
#' # from the fits, as if observed_data came from an outside source and
#' # observed_model were unknown:
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
#' model <- sim_model_from_fits(fits, observed_data, types)
#' new_data <- sim_events(model, n = 1000)
#' head(new_data)
#'
#' # Event-type distribution should be comparable between the observed and
#' # newly simulated data (a few simulated individuals reach the end of the
#' # observed follow-up, as "max_cens"):
#' event_levels <- levels(new_data$event)
#' rbind(
#'   observed = prop.table(table(factor(observed_data$event, event_levels))),
#'   simulated = prop.table(table(new_data$event))
#' )
#' @export
sim_model_from_fits <- function(fits, data, types, limits = list()) {
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

  var_names <- unique(unlist(lapply(fits, function(fit) {
    all.vars(stats::delete.response(stats::terms(fit)))
  })))
  # A variable that names another process (rather than a data column) is a
  # cross-process effect e.g. coxph(Surv(...) ~ L0 + relapse), where
  # relapse is itself a simulated process's event count, not a baseline
  # covariate to regenerate.
  covariate_names <- setdiff(var_names, names(types))
  missing_cols <- setdiff(covariate_names, names(data))
  if (length(missing_cols) > 0) {
    stop(
      "fits reference covariate(s) not found in data or in types (as a ",
      "cross-process effect): ",
      paste(missing_cols, collapse = ", "),
      "."
    )
  }

  # One row per individual, so individuals with more rows (more events)
  # aren't over-represented.
  if ("id" %in% names(data)) {
    data <- data[!duplicated(data$id), , drop = FALSE]
  }
  n_rows <- nrow(data)

  # A hidden row index, one sim_derived() per covariate reading its value at
  # that row, plus one sim_derived() dummy per non-reference level for
  # factor covariates (dummy names double as the coefficient names coxph()
  # itself produces, e.g. "region2").
  baseline_nodes <- list()
  baseline_nodes[[.sim_row_name]] <- sim_covariate(local({
    force(n_rows)
    function(N) sample.int(n_rows, N, replace = TRUE)
  }))
  for (nm in covariate_names) {
    col <- data[[nm]]
    if (is.factor(col)) {
      baseline_nodes[[nm]] <- .sim_resampled_column(as.integer(col))
      lv <- levels(col)
      for (i in seq_along(lv)[-1]) {
        baseline_nodes[[paste0(nm, lv[i])]] <- .sim_level_dummy(nm, i)
      }
    } else if (is.numeric(col) || is.logical(col)) {
      baseline_nodes[[nm]] <- .sim_resampled_column(as.numeric(col))
    } else {
      stop(
        "Covariate '",
        nm,
        "' must be a numeric, logical or factor column in data."
      )
    }
  }

  node_names <- c(names(baseline_nodes), names(types))
  process_nodes <- list()
  effects <- list()
  for (proc in names(fits)) {
    fit <- fits[[proc]]
    process_nodes[[proc]] <- sim_process(
      type = types[[proc]],
      limit = if (is.null(limits[[proc]])) Inf else limits[[proc]],
      cumhaz = .sim_basehaz(fit, proc)
    )

    cf <- stats::coef(fit)
    cf <- cf[!is.na(cf)]
    for (v in names(cf)) {
      from <- .sim_effect_from_coef(v, node_names)
      effects[[length(effects) + 1]] <- sim_effect(from, proc, unname(cf[[v]]))
    }
  }

  do.call(
    sim_model,
    c(baseline_nodes, process_nodes, list(effects = effects))
  )
}
