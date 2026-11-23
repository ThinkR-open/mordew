validate_arguments <- function(
  arguments,
  schema
) {
  check_fields(
    arguments,
    schema,
    NULL
  )
}

check_fields <- function(
  value,
  schema,
  path
) {
  stop_on_first(
    setdiff(
      names(value),
      names(schema$properties)
    ),
    "Unknown",
    path
  )
  stop_on_first(
    setdiff(
      schema$required,
      names(value)
    ),
    "Missing",
    path
  )
  for (name in names(value)) {
    check_value(
      value[[name]],
      schema$properties[[name]],
      field_path(
        path,
        name
      )
    )
  }
}

field_path <- function(
  path,
  name
) {
  if (is.null(path)) {
    return(
      name
    )
  }
  paste0(
    path,
    ".",
    name
  )
}

check_value <- function(
  value,
  schema,
  path
) {
  problem <- argument_problem(
    value,
    schema
  )
  if (!is.null(problem)) {
    stop(
      "Argument `",
      path,
      "` must ",
      problem,
      "."
    )
  }
  if (schema$type == "array") {
    for (i in seq_along(value)) {
      check_value(
        value[[i]],
        schema$items,
        paste0(
          path,
          "[",
          i - 1,
          "]"
        )
      )
    }
  }
  if (schema$type == "object") {
    check_fields(
      value,
      schema,
      path
    )
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
  if (
    !is.null(property$pattern) &&
      !grepl(
        property$pattern,
        value,
        perl = TRUE
      )
  ) {
    return(
      paste(
        "match the pattern",
        property$pattern
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
  problem,
  path
) {
  if (length(offending) > 0) {
    stop(
      problem,
      " argument `",
      field_path(
        path,
        offending[[1]]
      ),
      "`."
    )
  }
}
