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
    problem <- argument_problem(
      arguments[[name]],
      schema$properties[[name]]
    )
    if (!is.null(problem)) {
      stop(
        "Argument `",
        name,
        "` must ",
        problem,
        "."
      )
    }
  }
}

argument_problem <- function(
  value,
  property
) {
  if (
    !has_type(
      value,
      property$type
    )
  ) {
    return(
      paste(
        "be of type",
        property$type
      )
    )
  }
  if (!is.null(property$enum) && !value %in% property$enum) {
    return(
      paste(
        "be one of:",
        paste(
          property$enum,
          collapse = ", "
        )
      )
    )
  }
  if (!is.null(property$minimum) && value < property$minimum) {
    return(
      paste(
        "be at least",
        property$minimum
      )
    )
  }
  if (!is.null(property$maximum) && value > property$maximum) {
    return(
      paste(
        "be at most",
        property$maximum
      )
    )
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
    ),
    array = is.list(
      value
    ) &&
      is.null(
        names(
          value
        )
      ),
    object = is.list(
      value
    ) &&
      !is.null(
        names(
          value
        )
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
