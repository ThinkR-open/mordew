as_r_value <- function(
  value,
  schema
) {
  switch(
    schema$type,
    integer = as.integer(
      value
    ),
    number = as.numeric(
      value
    ),
    array = as_r_array(
      value,
      schema$items
    ),
    object = as_r_object(
      value,
      schema$properties
    ),
    value
  )
}

as_r_array <- function(
  value,
  items
) {
  prototype <- list(
    string = character(1),
    integer = integer(1),
    number = numeric(1),
    boolean = logical(1)
  )[[items$type]]
  if (is.null(prototype)) {
    return(
      lapply(
        value,
        as_r_value,
        items
      )
    )
  }
  vapply(
    value,
    as_r_value,
    prototype,
    items
  )
}

as_r_object <- function(
  value,
  properties
) {
  for (name in names(value)) {
    value[[name]] <- as_r_value(
      value[[name]],
      properties[[name]]
    )
  }
  value
}
