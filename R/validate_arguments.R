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
  for (name in names(arguments)) {
    type <- schema$properties[[name]]$type
    if (
      !has_type(
        arguments[[name]],
        type
      )
    ) {
      stop(
        "Argument `",
        name,
        "` must be of type ",
        type,
        "."
      )
    }
  }
}

has_type <- function(
  value,
  type
) {
  switch(
    type,
    string = is.character(
      value
    ),
    integer = is.numeric(
      value
    ) &&
      value ==
        round(
          value
        ),
    number = is.numeric(
      value
    ),
    boolean = is.logical(
      value
    )
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
