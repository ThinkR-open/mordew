#' Year summary
#'
#' Returns the totals of one year for each type of run: number of runs,
#' distance (km) and duration (hours). For month by month totals, use
#' summarise_runs_by_month.
#'
#' @param year Four-digit year.
#'
#' @mcpTool
#' @mcpType year type_integer(min = 2024, max = 2025)
#' @mcpReturns table
#' @mcpReadOnly
#' @mcpClosedWorld
#' @export
summarise_runs <- function(
  year
) {
  runs <- get_runs(
    year
  )
  totals(
    runs,
    list(
      type = runs$type
    )
  )
}
