# Breaking changes desired

- Standardize function names+args (snake-case)

- Rename `predict2()` to `predict_chf()`?

- `useOldVars = TRUE` silently ignores `N` in `simEventObj()`/`simEventCox()`.

- `cens` type/docs are inconsistent (logical vs 0/1) across
  `simDisease`/`simTreatment`/`simDropIn`.

- `followup` (wrappers) and `max_cens` (engines) are the same thing, named
  differently.

- Replace `simTreatment`/`simDropIn`'s ~20-30 individual
  `beta_X_Y`/`beta_X_Y_prime` scalar args with a `beta`/`beta_prime` matrix,
  like `simEventData` already uses.

- `sim.generic()`/`sim.from.data()` (ported from `MultiStateTMLE`) are now
  available as a general-purpose alternative to `simCRdata`/`simDisease`/
  `simDropIn`/`simStatinData`/`simSurvData`/`simTreatment` --- see
  `vignette("sim-generic")` for how each wrapper's default behavior maps to a
  `sim.generic()` spec. The six wrappers are still exported as-is;
  deprecating/removing them in favor of `sim.generic()` (which would also
  resolve the `beta_X_Y` scalar-arg and `followup`/`max_cens` naming items
  above) is a separate, not-yet-made decision. `sim.generic()` also currently
  has no `followup`/`max_cens` argument at all, unlike the wrappers.

- Currently the following is needed in `sim.generic()`: If `L0`/ `A0` are
  omitted, they are generated with `simEventData()`'s defaults (Uniform(0,1) and
  Bernoulli(0.5) respectively) but dropped from the output, since they weren't
  part of the requested design. Drop the reliance on `L0`, `A0` being forced.

# Docs

- Improve vignette + docstrings. More clear introduction also in README/getting
  started.

- Stop using `NULL` as default in ARGS; just give the actual default instead?

- Consider using reftip + quarto call out blocks via my packages :). Either as
  pkgdown or using altdown.

# Correctness

- While porting `sim.generic()`/`sim.from.data()` from `MultiStateTMLE`, fixed
  three bugs present in the originals (see `R/sim-generic.R`/
  `R/sim-from-data.R`): (1) `sim.generic()` fell back to `sim.object` based on
  `length(effects) == 0` rather than `missing(effects)`, so an explicit
  `effects = list()` was silently discarded; (2) `sim.generic()`'s
  `gen_L0`/`gen_A0` wiring to `simEventData()` was commented out, so a
  user-supplied `baseline$L0`/`baseline$A0` generator was silently ignored;
  (3) both functions could build `beta`'s row order as `A0, L0, ...` instead of
  the `L0, A0, ...` order `simEventData()` always assumes when renaming `beta`'s
  rows, silently swapping the `L0`/`A0` effects whenever the caller supplied
  `L0` (but not `A0`) explicitly. Worth porting these same fixes back into
  `MultiStateTMLE`.
