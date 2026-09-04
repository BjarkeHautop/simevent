#' Sample event types from matrix of probabilities
#'
#' @param probs A matrix where each column is a probability vector
#' @return A vector of sampled event types (0-indexed)
#' @keywords internal
#' @noRd
sampleEvents <- function(probs) {
  .Call('_simevent_sampleEventsCpp', PACKAGE = 'simevent', probs)
}
