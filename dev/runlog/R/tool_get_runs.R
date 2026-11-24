#' Runs
#'
#' Returns runs, newest first: date (YYYY-MM-DD), type, distance (km) and
#' duration (minutes). Use it to list the runs of a year or of a type.
#' Leave a filter out to ignore it.
#'
#' @param year Four-digit year of the runs.
#' @param type Type of run: "easy", "long", "interval" or "race".
#'
#' @mcpTool
#' @mcpType year type_integer(min = 2024, max = 2025, required = FALSE)
#' @mcpType type type_enum(c("easy", "long", "interval", "race"), required = FALSE)
#' @mcpReturns table
#' @mcpReadOnly
#' @mcpClosedWorld
#' @export
get_runs <- function(
  year = NULL,
  type = NULL
) {
  runs <- runs(
    type
  )
  if (!is.null(year)) {
    runs <- runs[
      startsWith(
        runs$date,
        as.character(
          year
        )
      ),
    ]
  }
  runs[
    rev(
      seq_len(
        nrow(
          runs
        )
      )
    ),
  ]
}
