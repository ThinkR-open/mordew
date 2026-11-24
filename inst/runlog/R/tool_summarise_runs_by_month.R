#' Month summary
#'
#' Returns the totals of each month of one year, all types of run
#' together: number of runs, distance (km) and duration (hours). For
#' totals by type of run, use summarise_runs.
#'
#' @param year Four-digit year.
#'
#' @mcpTool
#' @mcpType year type_integer(min = 2024, max = 2025)
#' @mcpReturns table
#' @mcpReadOnly
#' @mcpClosedWorld
#' @export
summarise_runs_by_month <- function(
  year
) {
  runs <- get_runs(
    year
  )
  totals(
    runs,
    list(
      month = as.integer(
        substr(
          runs$date,
          6,
          7
        )
      )
    )
  )
}
