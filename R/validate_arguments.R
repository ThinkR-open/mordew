validate_arguments <- function(
  arguments,
  schema
) {
  stop_on_first(
    setdiff(
      names(arguments),
      names(schema$properties)
    ),
    "Unknown"
  )
  stop_on_first(
    setdiff(
      schema$required,
      names(arguments)
    ),
    "Missing"
  )
}

stop_on_first <- function(
  offending,
  problem
) {
  if (length(offending) > 0) {
    stop(
      problem,
      " argument `",
      offending[[1]],
      "`."
    )
  }
}
