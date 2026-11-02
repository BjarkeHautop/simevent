#' Summarise a `sim_model()`
#'
#' Tabulates a [sim_model()]'s covariates, processes and effects.
#'
#' @param object A [sim_model()].
#' @param x A `summary.sim_model` object, as returned by `summary()`.
#' @param ... Not used.
#'
#' @return A list of three `data.frame`s: `covariates`, `processes` and
#'   `effects`.
#' @seealso [sim_model()]
#' @examples
#' model <- sim_model(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   relapse = sim_process("transient", eta = 0.2, nu = 1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect(death ~ age, coef = 0.03),
#'     sim_effect(death ~ relapse, coef = 1)
#'   )
#' )
#' model
#' summary(model)
#' @export
summary.sim_model <- function(object, ...) {
  shown <- object$covariates[!.sim_hidden(names(object$covariates))]
  covariates <- data.frame(
    name = names(shown),
    kind = vapply(
      shown,
      function(node) {
        if (inherits(node, "sim_derived")) {
          "derived"
        } else if (inherits(node, "sim_mark")) {
          "mark"
        } else {
          "baseline"
        }
      },
      character(1)
    ),
    row.names = NULL
  )
  processes <- data.frame(
    name = names(object$processes),
    type = vapply(object$processes, `[[`, character(1), "type"),
    baseline = vapply(
      object$processes,
      function(proc) if (is.null(proc$cumhaz)) "weibull" else "cumhaz",
      character(1)
    ),
    eta = vapply(object$processes, `[[`, numeric(1), "eta"),
    nu = vapply(object$processes, `[[`, numeric(1), "nu"),
    limit = vapply(object$processes, `[[`, numeric(1), "limit"),
    row.names = NULL
  )
  from <- vapply(object$effects, `[[`, character(1), "from")
  to <- vapply(object$effects, `[[`, character(1), "to")
  # Unroll effects into a mark over its updates: its own value in `from` is
  # the one before the update.
  marks <- names(object$covariates)[vapply(
    object$covariates,
    inherits,
    logical(1),
    "sim_mark"
  )]
  into_mark <- to %in% marks
  from[into_mark] <- vapply(
    which(into_mark),
    function(i) {
      .sim_deparse(.sim_index_symbol(object$effects[[i]]$expr, to[i]))
    },
    character(1)
  )
  to[into_mark] <- paste0(to[into_mark], "[k+1]")
  effects <- data.frame(
    from = from,
    to = to,
    coef = vapply(object$effects, `[[`, numeric(1), "coef"),
    row.names = NULL
  )
  structure(
    list(covariates = covariates, processes = processes, effects = effects),
    class = "summary.sim_model"
  )
}

#' @rdname summary.sim_model
#' @export
print.summary.sim_model <- function(x, ...) {
  cat("<sim_model> covariates\n")
  print(x$covariates, row.names = FALSE)
  cat("\n<sim_model> processes\n")
  print(x$processes, row.names = FALSE)
  cat("\n<sim_model> effects\n")
  print(x$effects, row.names = FALSE)
  if (any(endsWith(x$effects$to, "[k+1]"))) {
    cat("\nmark[k]: value after the mark's k-th update (k = 0: init)\n")
  }
  invisible(x)
}

# Expression `expr` with each use of the variable `name` replaced by
# `name[k]`; calls to `name` as a function of time are left as they are.
.sim_index_symbol <- function(expr, name) {
  if (identical(expr, as.name(name))) {
    return(call("[", expr, quote(k)))
  }
  if (is.call(expr)) {
    for (i in seq_along(expr)[-1]) {
      expr[[i]] <- .sim_index_symbol(expr[[i]], name)
    }
  }
  expr
}

#' Update a `sim_model()`
#'
#' Changes nodes and effects of an existing [sim_model()] and rebuilds it
#' through [sim_model()], so all of its checks run again. Useful for
#' sensitivity analyses and scenario grids built from one base model; for
#' fixing a covariate or scaling a hazard in a single simulation, see
#' [sim_events()]'s `intervene` instead.
#'
#' @param object A [sim_model()].
#' @param ... Named [sim_covariate()]/[sim_derived()]/[sim_mark()]/
#'   [sim_process()] objects. A name already in the model replaces that node
#'   in place; a new name is added after the existing nodes; `NULL` removes
#'   the node.
#' @param effects List of [sim_effect()]s. One with the same formula as an
#'   existing effect replaces it; any other is added.
#' @param drop_effects Formula, or list of formulas, of effects to remove,
#'   e.g. `death ~ treated`. Effects using a removed node must be dropped
#'   here.
#'
#' @return A [sim_model()].
#' @seealso [sim_model()], [summary.sim_model()]
#' @examples
#' model <- sim_model(
#'   age = sim_covariate(function(N) runif(N, min = 40, max = 80)),
#'   treated = sim_covariate(function(N) rbinom(N, 1, 0.5)),
#'   censoring = sim_process("censoring", eta = 0.1, nu = 1.1),
#'   death = sim_process("terminal", eta = 0.1, nu = 1.1),
#'   effects = list(
#'     sim_effect(death ~ age, coef = 0.03),
#'     sim_effect(death ~ treated, coef = -0.5)
#'   )
#' )
#'
#' update(
#'   model,
#'   death = sim_process("terminal", eta = 0.1, nu = 1.5),
#'   frailty = sim_covariate(function(N) rgamma(N, shape = 2, rate = 2)),
#'   treated = NULL,
#'   effects = list(sim_effect(death ~ log(frailty), coef = 1)),
#'   drop_effects = death ~ treated
#' )
#'
#' # A grid of treatment effects:
#' models <- lapply(c(-1, -0.5, 0), function(b) {
#'   update(model, effects = list(sim_effect(death ~ treated, coef = b)))
#' })
#' @export
update.sim_model <- function(
  object,
  ...,
  effects = list(),
  drop_effects = list()
) {
  checkmate::assert_class(object, "sim_model")
  changes <- list(...)
  if (length(changes) > 0) {
    checkmate::assert_list(changes, names = "unique")
  }
  effects <- .sim_flatten_effects(effects)
  if (inherits(drop_effects, "formula")) {
    drop_effects <- list(drop_effects)
  }
  checkmate::assert_list(drop_effects, types = "formula")
  drop_effects <- unlist(lapply(drop_effects, function(f) {
    parsed <- .sim_parse_formula(f)
    paste(parsed$to, "~", vapply(parsed$terms, .sim_deparse, character(1)))
  }))

  nodes <- c(object$covariates, object$processes)
  removed <- names(changes)[vapply(changes, is.null, logical(1))]
  unknown <- setdiff(removed, names(nodes))
  if (length(unknown) > 0) {
    stop(
      "update() can't remove node(s) not in the model: ",
      paste(unknown, collapse = ", ")
    )
  }
  nodes <- nodes[setdiff(names(nodes), removed)]
  for (nm in setdiff(names(changes), removed)) {
    nodes[[nm]] <- changes[[nm]]
  }

  old <- object$effects
  old_keys <- .sim_effect_keys(old)
  unknown <- setdiff(drop_effects, old_keys)
  if (length(unknown) > 0) {
    stop(
      "drop_effects names effect(s) not in the model: ",
      paste(unknown, collapse = "; "),
      ". Existing effects are: ",
      paste(old_keys, collapse = "; ")
    )
  }
  old <- old[!(old_keys %in% drop_effects)]
  old_keys <- old_keys[!(old_keys %in% drop_effects)]

  node_names <- c(names(object$covariates), names(object$processes))
  dangling <- old_keys[vapply(
    old,
    function(eff) any(.sim_effect_refs(eff, node_names) %in% removed),
    logical(1)
  )]
  if (length(dangling) > 0) {
    stop(
      "update() removes node(s) still used by effect(s): ",
      paste(dangling, collapse = "; "),
      ". Add them to drop_effects."
    )
  }

  new_keys <- .sim_effect_keys(effects)
  replace <- match(new_keys, old_keys)
  old[replace[!is.na(replace)]] <- effects[!is.na(replace)]

  do.call(
    sim_model,
    c(nodes, list(effects = c(old, effects[is.na(replace)])))
  )
}

# "<to> ~ <from>" for each of a list of sim_effect()s.
.sim_effect_keys <- function(effects) {
  vapply(
    effects,
    function(eff) paste(eff$to, "~", eff$from),
    character(1)
  )
}

# Node names a sim_effect() uses: its `to`, and its `from` (a node name, or
# the nodes its expression refers to).
.sim_effect_refs <- function(eff, node_names) {
  c(eff$to, .sim_expr_refs(eff$expr, node_names))
}
