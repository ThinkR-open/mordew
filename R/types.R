new_type <- function(
  .required,
  ...
) {
  list(
    schema = Filter(
      length,
      list(
        ...
      )
    ),
    required = .required
  )
}

type_string <- function(
  pattern = NULL,
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "string",
    pattern = pattern,
    description = description
  )
}

type_integer <- function(
  min = NULL,
  max = NULL,
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "integer",
    minimum = min,
    maximum = max,
    description = description
  )
}

type_number <- function(
  min = NULL,
  max = NULL,
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "number",
    minimum = min,
    maximum = max,
    description = description
  )
}

type_boolean <- function(
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "boolean",
    description = description
  )
}

type_enum <- function(
  values,
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "string",
    enum = as.list(
      values
    ),
    description = description
  )
}

type_array <- function(
  items,
  required = TRUE,
  description = NULL
) {
  new_type(
    required,
    type = "array",
    items = items$schema,
    description = description
  )
}

type_object <- function(
  ...,
  .required = TRUE,
  .description = NULL
) {
  fields <- list(
    ...
  )
  new_type(
    .required,
    type = "object",
    properties = lapply(
      fields,
      `[[`,
      "schema"
    ),
    required = as.list(
      names(fields)[vapply(
        fields,
        `[[`,
        logical(1),
        "required"
      )]
    ),
    additionalProperties = FALSE,
    description = .description
  )
}
