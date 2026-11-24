#' Fastest runs
#'
#' Returns the n fastest runs by pace, fastest first: date (YYYY-MM-DD),
#' type, distance (km), duration (minutes) and pace (minutes per km).
#' Leave the type out to compare all runs. For the longest runs, use
#' longest_runs.
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
fastest_runs <- function(
  n,
  type = NULL
) {
  runs <- runs(
    type
  )
  runs$pace <- round(
    runs$duration_min / runs$distance_km,
    2
  )
  utils::head(
    runs[
      order(
        runs$pace
      ),
    ],
    n
  )
}
