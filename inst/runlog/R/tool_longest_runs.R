#' Longest runs
#'
#' Returns the n longest runs, longest first: date (YYYY-MM-DD), type,
#' distance (km) and duration (minutes). Leave the type out to compare all
#' runs. For the fastest runs, use fastest_runs.
#'
#' @param n Number of runs, from 1 to 50.
#' @param type Type of run: "easy", "long", "interval" or "race".
#'
#' @mcpTool
#' @mcpType n type_integer(min = 1, max = 50)
#' @mcpType type type_enum(c("easy", "long", "interval", "race"), required = FALSE)
#' @mcpReturns table
#' @mcpReadOnly
#' @mcpClosedWorld
#' @export
longest_runs <- function(
  n,
  type = NULL
) {
  runs <- runs(
    type
  )
  utils::head(
    runs[
      order(
        -runs$distance_km
      ),
    ],
    n
  )
}
