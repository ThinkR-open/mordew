#' Stop when a case fails too often
#'
#' Computes the pass rate of each case of [run_evals()] and stops, listing
#' them, when some fall below `min`. A rate per case, not overall: a case
#' that always fails cannot hide among cases that pass.
#'
#' @param results Results of [run_evals()].
#' @param min Lowest pass rate accepted for each case, between 0 and 1.
#'
#' @return `results`, invisibly.
#'
#' @export
assert_pass_rate <- function(
  results,
  min = 0.8
) {
  rates <- tapply(
    results$passed,
    results$question,
    mean
  )
  below <- rates[rates < min]
  if (length(below) > 0) {
    stop(
      "Cases below a pass rate of ",
      100 * min,
      "%:\n",
      paste0(
        names(
          below
        ),
        " (",
        round(
          100 * below
        ),
        "%)",
        collapse = "\n"
      ),
      call. = FALSE
    )
  }
  invisible(
    results
  )
}
