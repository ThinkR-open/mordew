runs <- function(
  type = NULL
) {
  runs <- utils::read.csv(
    system.file(
      "extdata",
      "runs.csv",
      package = "runlog"
    )
  )
  if (!is.null(type)) {
    runs <- runs[runs$type == type, ]
  }
  runs
}

totals <- function(
  runs,
  by
) {
  totals <- stats::aggregate(
    cbind(
      runs = 1,
      distance_km = runs$distance_km,
      hours = runs$duration_min / 60
    ),
    by,
    sum
  )
  totals$hours <- round(
    totals$hours,
    1
  )
  totals
}
