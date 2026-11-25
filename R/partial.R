#' Accept part of an expected argument
#'
#' Marks an expected argument of an eval case: the model's value matches when
#' it is part of `x`, ignoring case.
#'
#' @param x Expected value, a string.
#'
#' @return `x`, with class `partial`.
#'
#' @export
partial <- function(
  x
) {
  structure(
    x,
    class = "partial"
  )
}
