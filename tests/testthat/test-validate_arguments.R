test_that("validate_arguments() rejects an unknown argument", {
  expect_error(
    validate_arguments(
      list(
        surface = "road",
        speed = 12
      ),
      type_object(
        surface = type_string()
      )$schema
    ),
    "Unknown argument `speed`."
  )
})

test_that("validate_arguments() rejects a missing required argument", {
  expect_error(
    validate_arguments(
      list(),
      type_object(
        surface = type_string()
      )$schema
    ),
    "Missing argument `surface`."
  )
})

test_that("validate_arguments() rejects a string argument of another type", {
  expect_error(
    validate_arguments(
      list(
        surface = 12
      ),
      type_object(
        surface = type_string()
      )$schema
    ),
    "Argument `surface` must be of type string."
  )
})

test_that("validate_arguments() accepts an integer with a zero fractional part", {
  expect_no_error(
    validate_arguments(
      list(
        year = 2023.0
      ),
      type_object(
        year = type_integer()
      )$schema
    )
  )
})

test_that("validate_arguments() rejects a fractional number for an integer", {
  expect_error(
    validate_arguments(
      list(
        year = 2023.5
      ),
      type_object(
        year = type_integer()
      )$schema
    ),
    "Argument `year` must be of type integer."
  )
})

test_that("validate_arguments() rejects a number argument of another type", {
  expect_error(
    validate_arguments(
      list(
        distance = "10"
      ),
      type_object(
        distance = type_number()
      )$schema
    ),
    "Argument `distance` must be of type number."
  )
})

test_that("validate_arguments() rejects a boolean argument of another type", {
  expect_error(
    validate_arguments(
      list(
        trail = "true"
      ),
      type_object(
        trail = type_boolean()
      )$schema
    ),
    "Argument `trail` must be of type boolean."
  )
})
