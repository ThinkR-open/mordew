test_that("a type wraps its JSON Schema and whether it is required", {
  expect_equal(
    type_string(),
    list(
      schema = list(
        type = "string"
      ),
      required = TRUE
    )
  )
})

test_that("a type can be optional and described", {
  expect_equal(
    type_boolean(
      required = FALSE,
      description = "Include trail runs."
    ),
    list(
      schema = list(
        type = "boolean",
        description = "Include trail runs."
      ),
      required = FALSE
    )
  )
})

test_that("type_string() takes a pattern", {
  expect_equal(
    type_string(
      pattern = "^[0-9]+$"
    )$schema,
    list(
      type = "string",
      pattern = "^[0-9]+$"
    )
  )
})

test_that("type_integer() and type_number() take bounds", {
  expect_equal(
    type_integer(
      min = 2015
    )$schema,
    list(
      type = "integer",
      minimum = 2015
    )
  )
  expect_equal(
    type_number(
      min = 0,
      max = 1
    )$schema,
    list(
      type = "number",
      minimum = 0,
      maximum = 1
    )
  )
})

test_that("type_enum() lists its values as a JSON array", {
  expect_equal(
    type_enum(
      c(
        "road",
        "trail",
        "track"
      )
    )$schema,
    list(
      type = "string",
      enum = list(
        "road",
        "trail",
        "track"
      )
    )
  )
})

test_that("type_array() takes the schema of its items", {
  expect_equal(
    type_array(
      type_string()
    )$schema,
    list(
      type = "array",
      items = list(
        type = "string"
      )
    )
  )
})

test_that("type_object() lists its fields and the required ones", {
  expect_equal(
    type_object(
      surface = type_string(),
      year = type_integer(
        required = FALSE
      ),
      .required = FALSE,
      .description = "A filter."
    ),
    list(
      schema = list(
        type = "object",
        properties = list(
          surface = list(
            type = "string"
          ),
          year = list(
            type = "integer"
          )
        ),
        required = list(
          "surface"
        ),
        additionalProperties = FALSE,
        description = "A filter."
      ),
      required = FALSE
    )
  )
})

test_that("type_object() without fields only rejects extra fields", {
  expect_equal(
    type_object()$schema,
    list(
      type = "object",
      additionalProperties = FALSE
    )
  )
})
