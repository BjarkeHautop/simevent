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

# Docs

- Improve vignette + docstrings. More clear introduction also in README/getting
  started.

- Stop using `NULL` as default in ARGS; just give the actual default instead?

- Consider using reftip + quarto call out blocks via my packages :). Either as
  pkgdown or using altdown.
