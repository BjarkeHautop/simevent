# Draws baseline covariates in declared order, as a named list of length-N
# numeric vectors, so a generator may depend on any covariate drawn before
# it (matched by argument name).
draw_baseline_covariates <- function(covs, n) {
  drawn <- list()
  for (nm in names(covs)) {
    f <- covs[[nm]]
    arg_names <- setdiff(names(formals(f)), "N")
    drawn[[nm]] <- do.call(f, c(list(N = n), drawn[arg_names]))
  }
  drawn
}

# Applies a sim_events() `intervene` list to a model: fixes an
# intervened covariate/sim_derived() to a constant generator, and scales an
# intervened process's baseline eta.
apply_intervention <- function(model, intervene) {
  covariate_names <- names(model$covariates)
  process_names <- names(model$processes)

  covs <- lapply(model$covariates, .sim_initial)
  for (nm in intersect(names(intervene), covariate_names)) {
    value <- intervene[[nm]]
    covs[[nm]] <- local({
      force(value)
      function(N) rep(value, N)
    })
  }

  # A cumhaz process has no eta; its curve is scaled by 1 instead.
  eta <- vapply(model$processes, `[[`, numeric(1), "eta")
  eta[is.na(eta)] <- 1
  for (nm in intersect(names(intervene), process_names)) {
    eta[nm] <- eta[nm] * intervene[[nm]]
  }

  list(covs = covs, eta = eta)
}

# Each individual's history so far, one column per individual: `time` and
# `type` (process name) of their events in the first `n` rows, and for each
# mark in `marks`, its value at baseline (row 1) and after each event (row
# i + 1).
.sim_history <- function(time, type, n, marks = list()) {
  list(time = time, type = type, n = n, marks = marks)
}

# `history` restricted to individuals (columns) `cols`.
.sim_history_cols <- function(history, cols) {
  if (is.null(history)) {
    return(NULL)
  }
  .sim_history(
    history$time[, cols, drop = FALSE],
    history$type[, cols, drop = FALSE],
    history$n,
    lapply(history$marks, function(m) m[, cols, drop = FALSE])
  )
}

# The time of process `proc`'s k-th event so far per individual, counting
# back from the latest if k < 0, or 0 where there are fewer than abs(k).
.sim_event_time <- function(history, proc, k) {
  hit <- history$type[seq_len(history$n), , drop = FALSE] == proc
  vapply(
    seq_len(ncol(history$time)),
    function(j) {
      w <- which(hit[, j])
      if (length(w) < abs(k)) {
        return(0)
      }
      history$time[w[if (k > 0) k else length(w) + 1 + k], j]
    },
    numeric(1)
  )
}

# Per entry of `s` (individual rep_len(columns, length(s))), the number of
# that individual's events (of process `proc` only, if given) at or before
# time s.
.sim_events_by <- function(history, s, proc = NULL) {
  rows <- seq_len(history$n)
  cols <- rep_len(seq_len(ncol(history$time)), length(s))
  by <- history$time[rows, cols, drop = FALSE] <= rep(s, each = history$n)
  if (!is.null(proc)) {
    type <- history$type[rows, cols, drop = FALSE]
    by <- by & !is.na(type) & type == proc
  }
  colSums(by)
}

# Evaluation environment for sim_effect() `from` expressions: covariates and
# event counts bound by name, `t` (current time), event_time(), which reads
# the process name out of its unevaluated argument, and each node called as
# a function of time in `effects`. Those functions sit in the parent
# environment, so R's function lookup skips over the node's value to reach
# them. With rep_times > 1, covariates/event_counts/t cover rep_times time
# points per individual (rep(x, times = rep_times) layout) while `history`
# covers each individual once, so its results are replicated to match.
.sim_effect_env <- function(
  effects,
  covariates,
  event_counts,
  process_names,
  t,
  history,
  rep_times = 1
) {
  funs <- new.env(parent = parent.frame())
  n_points <- length(event_counts[[1]])
  funs$event_time <- function(proc, k) {
    rep(
      .sim_event_time(history, deparse(substitute(proc)), k),
      times = rep_times
    )
  }
  called <- unique(unlist(lapply(effects, function(eff) {
    .sim_called(eff$expr)
  })))
  for (nm in intersect(called, c(names(covariates), process_names))) {
    funs[[nm]] <- local({
      nm <- nm
      function(s) {
        s <- rep_len(s, n_points)
        if (nm %in% process_names) {
          return(.sim_events_by(history, s, nm))
        }
        mark <- history$marks[[nm]]
        if (is.null(mark)) {
          return(covariates[[nm]])
        }
        cols <- rep_len(seq_len(ncol(mark)), n_points)
        mark[cbind(.sim_events_by(history, s) + 1, cols)]
      }
    })
  }
  env <- list2env(c(covariates, event_counts), parent = funs)
  env$t <- t
  env
}

# For each process, the multiplicative hazard effect exp(sum of incoming
# sim_effect() coefs * current value of their `from`); see
# .sim_linear_predictors(). Returns a length(event_counts[[1]]) x
# length(process_names) matrix.
process_hazard_multipliers <- function(
  effects,
  covariates,
  event_counts,
  process_names,
  t = NULL,
  history = NULL,
  rep_times = 1
) {
  exp(.sim_linear_predictors(
    effects,
    covariates,
    event_counts,
    process_names,
    targets = process_names,
    t = t,
    history = history,
    rep_times = rep_times
  ))
}

# For each of `targets` (processes or marks), the sum of incoming
# sim_effect() coefs * current value of their `from`; effects into anything
# else are ignored. `from` naming a covariate or process directly is looked
# up by name; anything else is parsed and evaluated as an R expression
# in .sim_effect_env().
# Returns a length(event_counts[[1]]) x length(targets) matrix.
# rep_times: see .sim_effect_env().
.sim_linear_predictors <- function(
  effects,
  covariates,
  event_counts,
  process_names,
  targets,
  t = NULL,
  history = NULL,
  rep_times = 1
) {
  n <- length(event_counts[[1]])
  lp <- matrix(
    0,
    nrow = n,
    ncol = length(targets),
    dimnames = list(NULL, targets)
  )
  effects <- Filter(function(eff) eff$to %in% targets, effects)
  env <- NULL
  for (eff in effects) {
    value <- covariates[[eff$from]]
    if (is.null(value)) {
      value <- event_counts[[eff$from]]
    }
    if (is.null(value)) {
      if (is.null(env)) {
        env <- .sim_effect_env(
          effects,
          covariates,
          event_counts,
          process_names,
          t,
          history,
          rep_times
        )
      }
      value <- eval(eff$expr, envir = env)
    }
    lp[, eff$to] <- lp[, eff$to] + eff$coef * value
  }
  lp
}

# Each process's unscaled cumulative baseline hazard H(t) and hazard h(t),
# as vectorized functions of t (eta multiplies both): t^nu and
# nu * t^(nu - 1) for a Weibull process, and for a cumhaz process its curve
# interpolated linearly from 0 at time 0 (only defined up to its last time;
# see .sim_cumhaz_end()).
.sim_baselines <- function(processes) {
  lapply(processes, function(proc) {
    if (is.null(proc$cumhaz)) {
      nu <- proc$nu
      return(list(
        H = function(t) t^nu,
        h = function(t) nu * t^(nu - 1)
      ))
    }
    knots <- c(0, proc$cumhaz$time)
    values <- c(0, proc$cumhaz$hazard)
    slopes <- diff(values) / diff(knots)
    list(
      H = function(t) stats::approx(knots, values, xout = t, rule = 2)$y,
      # Slope of the segment ending at t (so an event time on a knot takes
      # the slope of the segment it was reached through).
      h = function(t) {
        segment <- findInterval(t, knots, left.open = TRUE)
        slopes[pmin(pmax(segment, 1), length(slopes))]
      }
    )
  })
}

# Where follow-up ends because a cumhaz process's curve does: its earliest
# last time, or Inf without cumhaz processes.
.sim_cumhaz_end <- function(processes) {
  ends <- vapply(
    processes,
    function(proc) {
      if (is.null(proc$cumhaz)) Inf else max(proc$cumhaz$time)
    },
    numeric(1)
  )
  min(ends, Inf)
}

# n x K matrix of each process's (unscaled) cumulative baseline hazard at x.
.sim_cumhaz_matrix <- function(baselines, x) {
  matrix(unlist(lapply(baselines, function(b) b$H(x))), nrow = length(x))
}

# Samples the time increment to each alive individual's next event for
# models with a cumhaz process: solves
# sum_k rate[, k] * (H_k(t) - H_k(t_now)) = Exp(1) draw for t by bisection
# on [t_now, max_cens], or returns the increment to max_cens if the draw
# isn't reached before it.
sample_next_event_times_general <- function(
  t_now,
  phi_alive,
  risk_alive,
  eta,
  baselines,
  max_cens
) {
  n <- length(t_now)
  v <- -log(stats::runif(n))
  rate <- t(risk_alive) * rep(eta, each = n) * phi_alive
  base_now <- .sim_cumhaz_matrix(baselines, t_now)
  reached <- function(x, ind) {
    added <- .sim_cumhaz_matrix(baselines, x) -
      base_now[ind, , drop = FALSE]
    rowSums(rate[ind, , drop = FALSE] * added) >= v[ind]
  }

  increment <- max_cens - t_now
  ind <- which(reached(rep(max_cens, n), seq_len(n)))
  lo <- t_now[ind]
  hi <- rep(max_cens, length(ind))
  for (i in seq_len(60)) {
    mid <- (lo + hi) / 2
    above <- reached(mid, ind)
    hi[above] <- mid[above]
    lo[!above] <- mid[!above]
  }
  increment[ind] <- (lo + hi) / 2 - t_now[ind]
  increment
}

# Samples the time increment to each alive individual's next event, for one
# iteration of the simulation loop: the closed-form vectorized path when
# every process shares one Weibull shape/scale (same_params), else the
# per-individual numerical inverse (inverseScHazCpp) via inverseScHaz().
sample_next_event_times <- function(
  t_now,
  phi_alive,
  risk_alive,
  eta,
  nu,
  same_params,
  lower,
  upper
) {
  v <- -log(stats::runif(length(t_now)))

  if (same_params) {
    denom <- colSums(risk_alive * eta * t(phi_alive))
    (v / denom + t_now^nu[1])^(1 / nu[1]) - t_now
  } else {
    n_alive <- length(t_now)
    vapply(
      seq_len(n_alive),
      function(j) {
        inverseScHaz(
          v[j],
          t_now[j],
          lower = lower,
          upper = upper,
          eta = eta,
          nu = nu,
          phi = phi_alive[j, ],
          at_risk = risk_alive[, j]
        )
      },
      numeric(1)
    )
  }
}

# Whether any sim_effect() `from` expression refers to the current time `t`,
# so hazard multipliers change between events and have to be re-evaluated
# over time rather than once per event.
.sim_uses_time <- function(effects) {
  any(vapply(
    effects,
    function(eff) {
      "t" %in% all.vars(eff$expr)
    },
    logical(1)
  ))
}

# TODO: Improve this

# Samples each alive individual's next event time when hazard multipliers
# depend on `t`. Between events only `t` changes, so time is split into steps
# on a global grid (multiples of time_step): within a step, multipliers are
# held at their value at the step's midpoint and the Weibull baseline is
# integrated exactly. The cumulative hazard is accumulated step by step
# (vectorized over individuals and over blocks of steps) until it crosses
# each individual's Exp(1) draw, and the event time is then solved for
# exactly within that step. Returns the new absolute event times (max_cens
# for anyone not reaching an event before it) and the multipliers in force
# at those times (for sample_event_types()).
sample_next_event_times_td <- function(
  t_now,
  covariates,
  event_counts,
  risk_alive,
  eta,
  nu,
  baselines,
  effects,
  process_names,
  history,
  max_cens,
  time_step,
  upper,
  max_points = 1e6
) {
  n <- length(t_now)
  num_proc <- length(process_names)
  v <- -log(stats::runif(n))

  event_time <- rep(max_cens, n)
  phi <- matrix(
    1,
    nrow = n,
    ncol = num_proc,
    dimnames = list(NULL, process_names)
  )
  left <- t_now
  cum_haz <- numeric(n)
  searching <- which(left < max_cens)
  block <- 16L

  while (length(searching) > 0) {
    m <- length(searching)
    b <- as.integer(max(1, min(block, floor(max_points / m))))

    # m x b step boundaries: from each individual's current position to the
    # next b grid points, capped at max_cens.
    grid <- outer(floor(left[searching] / time_step) + 1, 0:(b - 1), `+`)
    rights <- grid * time_step
    capped <- rights > max_cens
    rights[capped] <- max_cens
    lefts <- cbind(left[searching], rights[, -b, drop = FALSE])

    # Multipliers at every step midpoint, one row per (individual, step) in
    # rep(searching, times = b) order.
    point_ind <- rep(searching, times = b)
    phi_pts <- process_hazard_multipliers(
      effects,
      lapply(covariates, `[`, point_ind),
      lapply(event_counts, `[`, point_ind),
      process_names,
      t = as.vector((lefts + rights) / 2),
      history = .sim_history_cols(history, searching),
      rep_times = b
    )
    rate_ind <- t(risk_alive[, searching, drop = FALSE]) * rep(eta, each = m)
    rate_pts <- phi_pts * rate_ind[rep(seq_len(m), times = b), , drop = FALSE]

    # Baseline cumulative hazard over each step. Step ends are grid points,
    # so a Weibull process's powers come from one lookup table instead of
    # m * b pow() calls.
    grid_min <- min(grid)
    grid_pts <- seq(grid_min, max(grid)) * time_step
    base_pts <- matrix(0, nrow = m * b, ncol = num_proc)
    for (k in seq_len(num_proc)) {
      if (is.na(nu[k])) {
        H <- baselines[[k]]$H
        base_pts[, k] <- H(as.vector(rights)) - H(as.vector(lefts))
        next
      }
      pow_table <- grid_pts^nu[k]
      right_pow <- matrix(pow_table[grid - grid_min + 1], nrow = m)
      right_pow[capped] <- max_cens^nu[k]
      left_pow <- cbind(left[searching]^nu[k], right_pow[, -b, drop = FALSE])
      base_pts[, k] <- right_pow - left_pow
    }
    step_haz <- matrix(rowSums(rate_pts * base_pts), nrow = m, ncol = b)

    cum_steps <- step_haz
    cum_steps[, 1] <- cum_steps[, 1] + cum_haz[searching]
    for (j in seq_len(b)[-1]) {
      cum_steps[, j] <- cum_steps[, j - 1] + step_haz[, j]
    }
    crossed <- cum_steps >= v[searching]
    hit <- which(rowSums(crossed) > 0)

    if (length(hit) > 0) {
      step <- max.col(crossed[hit, , drop = FALSE], ties.method = "first")
      at <- cbind(hit, step)
      point <- (step - 1) * m + hit
      remaining <- v[searching[hit]] - (cum_steps[at] - step_haz[at])
      event_time[searching[hit]] <- .sim_solve_in_step(
        lefts[at],
        rights[at],
        rate_pts[point, , drop = FALSE],
        nu,
        baselines,
        remaining
      )
      phi[searching[hit], ] <- phi_pts[point, ]
    }

    miss <- setdiff(seq_len(m), hit)
    left[searching[miss]] <- rights[miss, b]
    cum_haz[searching[miss]] <- cum_steps[miss, b]
    searching <- searching[miss][left[searching[miss]] < max_cens]

    if (any(left[searching] > upper)) {
      stop(
        "No event before time ",
        upper,
        " for some individual(s): their total hazard is (close to) zero."
      )
    }
    block <- min(block * 2L, 4096L)
  }

  list(time = event_time, phi = phi)
}

# Solves sum_k rate[, k] * (H_k(x) - H_k(left)) = remaining for x in
# [left, right], per row: closed form when every process is Weibull with one
# shared shape nu, otherwise bisection (the left-hand side is increasing in
# x).
.sim_solve_in_step <- function(
  left,
  right,
  rate,
  nu,
  baselines,
  remaining
) {
  if (!anyNA(nu) && all(nu == nu[1])) {
    x <- (remaining / rowSums(rate) + left^nu[1])^(1 / nu[1])
    return(pmin(pmax(x, left), right))
  }
  lo <- left
  hi <- right
  base_left <- .sim_cumhaz_matrix(baselines, left)
  for (i in seq_len(60)) {
    mid <- (lo + hi) / 2
    added <- .sim_cumhaz_matrix(baselines, mid) - base_left
    above <- rowSums(rate * added) >= remaining
    hi[above] <- mid[above]
    lo[!above] <- mid[!above]
  }
  (lo + hi) / 2
}

# Samples which process fires next for each alive individual, given their
# updated times: vectorized event intensities across all alive individuals,
# then sampleEvents() draws one event type per individual. Anyone who has
# reached max_cens gets "max_cens" instead of a process. Returns a character
# vector of process names (names(eta)).
sample_event_types <- function(
  t_alive,
  phi_alive,
  risk_alive,
  eta,
  nu,
  baselines,
  max_cens
) {
  num_events <- length(eta)
  if (anyNA(nu)) {
    hazard_mat <- matrix(
      unlist(lapply(baselines, function(b) b$h(t_alive))),
      nrow = num_events,
      byrow = TRUE
    )
    lambda_mat <- risk_alive * eta * hazard_mat * t(phi_alive)
  } else {
    pow_mat <- outer(nu - 1, t_alive, FUN = function(p, tt) tt^p)
    lambda_mat <- risk_alive * eta * nu * pow_mat * t(phi_alive)
  }

  # Placeholder intensities for those reaching max_cens (overwritten below),
  # so their columns don't divide by zero.
  censored <- t_alive >= max_cens
  lambda_mat[, censored] <- 1
  probs_mat <- lambda_mat / rep(colSums(lambda_mat), each = num_events)

  # sampleEvents() returns 0-indexed rows of probs_mat.
  events <- names(eta)[sampleEvents(probs_mat) + 1L]
  events[censored] <- "max_cens"
  events
}

# New values of mark `nm` for individuals `rows`, from its sim_mark() draw
# function given N and `lp`, the linear predictor of the effects into it at
# the current state (`history` including the current event).
.sim_draw_mark <- function(
  nm,
  draw,
  rows,
  effects,
  covariates,
  event_counts,
  process_names,
  t,
  history
) {
  lp <- .sim_linear_predictors(
    effects,
    lapply(covariates, `[`, rows),
    lapply(event_counts, `[`, rows),
    process_names,
    targets = nm,
    t = t[rows],
    history = .sim_history_cols(history, rows)
  )[, nm]
  args <- list(N = length(rows), lp = lp)
  value <- do.call(draw, args[names(formals(draw))])
  if (!is.numeric(value) || length(value) != length(rows)) {
    stop(
      "sim_mark() '",
      nm,
      "''s draw must return a numeric vector of length N (",
      length(rows),
      ")."
    )
  }
  value
}

# Top-level driver, called by sim_events(): draws baseline covariates,
# then repeatedly samples a next-event time and type for everyone still
# alive until all individuals have hit a censoring/terminal event.
run_sim <- function(
  model,
  n,
  intervene = list(),
  cens = 1,
  max_cens = Inf,
  max_events = 50,
  lower = 1e-25,
  upper = 1e8,
  time_step = 0.01
) {
  process_names <- names(model$processes)
  types <- vapply(model$processes, `[[`, character(1), "type")
  ending_events <- c(
    process_names[types %in% c("censoring", "terminal")],
    "max_cens"
  )
  transient_names <- process_names[types == "transient"]

  intervened <- apply_intervention(model, intervene)
  covariates <- draw_baseline_covariates(intervened$covs, n)
  is_mark <- vapply(model$covariates, inherits, logical(1), "sim_mark")
  # Each mark's baseline value is also output, as <mark>_0 right after it,
  # since redraws overwrite it.
  mark_init <- stats::setNames(
    covariates[is_mark],
    sprintf("%s_0", names(covariates)[is_mark])
  )
  output_covariates <- unlist(lapply(
    names(covariates)[!.sim_hidden(names(covariates))],
    function(nm) if (is_mark[[nm]]) c(nm, paste0(nm, "_0")) else nm
  ))
  # An intervened mark stays fixed, so isn't redrawn.
  marks <- model$covariates[is_mark]
  marks <- marks[setdiff(names(marks), names(intervene))]
  # Effects into marks only enter their draws, not the hazards.
  into_process <- vapply(
    model$effects,
    function(eff) eff$to %in% process_names,
    logical(1)
  )
  process_effects <- model$effects[into_process]
  mark_effects <- model$effects[!into_process]

  eta <- intervened$eta
  nu <- vapply(model$processes, `[[`, numeric(1), "nu")
  weibull_only <- !anyNA(nu)
  same_params <- weibull_only && all(nu[1] == nu) && all(eta[1] == eta)
  baselines <- .sim_baselines(model$processes)
  max_cens <- min(max_cens, .sim_cumhaz_end(model$processes))

  at_risk_fn <- .sim_at_risk(model, cens)
  uses_time <- .sim_uses_time(process_effects)

  event_counts <- stats::setNames(
    replicate(length(process_names), rep(0, n), simplify = FALSE),
    process_names
  )

  # Full per-individual history, so sim_effect() expressions can use
  # event_time() and nodes as functions of time. Only the marks called as
  # functions of time need their values logged.
  called <- unique(unlist(lapply(model$effects, function(eff) {
    .sim_called(eff$expr)
  })))
  timed_marks <- intersect(called, names(marks))
  history <- .sim_history(
    time = matrix(0, nrow = max_events, ncol = n),
    type = matrix(NA_character_, nrow = max_events, ncol = n),
    n = 0,
    marks = lapply(covariates[timed_marks], function(value) {
      log <- matrix(NA_real_, nrow = max_events + 1, ncol = n)
      log[1, ] <- value
      log
    })
  )

  t_k <- rep(0, n)
  alive <- seq_len(n)
  res_list <- vector("list", max_events)
  idx <- 1

  while (length(alive) != 0) {
    covariates_alive <- lapply(covariates, `[`, alive)
    event_counts_alive <- lapply(event_counts, `[`, alive)

    risk_alive <- at_risk_fn(event_counts_alive)

    if (uses_time) {
      draw <- sample_next_event_times_td(
        t_k[alive],
        covariates_alive,
        event_counts_alive,
        risk_alive,
        eta,
        nu,
        baselines,
        process_effects,
        process_names,
        history = .sim_history_cols(history, alive),
        max_cens = max_cens,
        time_step = time_step,
        upper = upper
      )
      t_k[alive] <- draw$time
      phi_alive <- draw$phi
    } else {
      phi_alive <- process_hazard_multipliers(
        process_effects,
        covariates_alive,
        event_counts_alive,
        process_names,
        t = t_k[alive],
        history = .sim_history_cols(history, alive)
      )
      w <- if (weibull_only) {
        sample_next_event_times(
          t_k[alive],
          phi_alive,
          risk_alive,
          eta,
          nu,
          same_params,
          lower,
          upper
        )
      } else {
        sample_next_event_times_general(
          t_k[alive],
          phi_alive,
          risk_alive,
          eta,
          baselines,
          max_cens
        )
      }
      t_k[alive] <- t_k[alive] + w
    }
    t_k[t_k > max_cens] <- max_cens
    t_alive <- t_k[alive]

    events <- sample_event_types(
      t_alive,
      phi_alive,
      risk_alive,
      eta,
      nu,
      baselines,
      max_cens
    )

    for (nm in process_names) {
      hit <- alive[events == nm]
      event_counts[[nm]][hit] <- event_counts[[nm]][hit] + 1
    }
    history$time[idx, ] <- t_k
    history$type[idx, alive] <- events
    history$n <- idx
    for (nm in timed_marks) {
      history$marks[[nm]][idx + 1, alive] <- covariates[[nm]][alive]
    }

    for (nm in names(marks)) {
      hit <- alive[events %in% marks[[nm]]$update]
      if (length(hit) > 0) {
        covariates[[nm]][hit] <- .sim_draw_mark(
          nm,
          marks[[nm]]$draw,
          hit,
          mark_effects,
          covariates,
          event_counts,
          process_names,
          t_k,
          history
        )
        if (nm %in% timed_marks) {
          history$marks[[nm]][idx + 1, hit] <- covariates[[nm]][hit]
        }
      }
    }

    result_cols <- c(
      list(id = alive, time = t_k[alive], event = events),
      lapply(c(covariates, mark_init)[output_covariates], `[`, alive),
      stats::setNames(
        lapply(transient_names, function(nm) event_counts[[nm]][alive]),
        transient_names
      )
    )
    res_list[[idx]] <- data.table::as.data.table(result_cols)

    idx <- idx + 1
    alive <- alive[!events %in% ending_events]

    if (length(alive) != 0 && idx > max_events) {
      stop(
        "max_events (",
        max_events,
        ") exceeded before a terminal event ",
        "occurred for all individuals. Increase max_events or adjust ",
        "at_risk/beta so that a terminal event becomes certain."
      )
    }
  }

  event <- NULL
  res <- data.table::rbindlist(res_list)
  event_levels <- c(process_names, if (is.finite(max_cens)) "max_cens")
  res[, event := factor(event, levels = event_levels)]
  data.table::setkeyv(res, "id")
  res[]
}
