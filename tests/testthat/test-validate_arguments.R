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

test_that("validate_arguments() rejects an object for an array", {
  expect_error(
    validate_arguments(
      list(
        surfaces = list(
          first = "road"
        )
      ),
      type_object(
        surfaces = type_array(
          type_string()
        )
      )$schema
    ),
    "Argument `surfaces` must be of type array."
  )
})

test_that("validate_arguments() rejects an array for an object", {
  expect_error(
    validate_arguments(
      list(
        period = list(
          2023
        )
      ),
      type_object(
        period = type_object(
          year = type_integer()
        )
      )$schema
    ),
    "Argument `period` must be of type object."
  )
})

test_that("validate_arguments() rejects a value outside the enum", {
  expect_error(
    validate_arguments(
      list(
        surface = "beach"
      ),
      type_object(
        surface = type_enum(
          c(
            "road",
            "trail",
            "track"
          )
        )
      )$schema
    ),
    "Argument `surface` must be one of: road, trail, track."
  )
})

test_that("validate_arguments() rejects a value under the minimum", {
  expect_error(
    validate_arguments(
      list(
        year = 2010
      ),
      type_object(
        year = type_integer(
          min = 2015
        )
      )$schema
    ),
    "Argument `year` must be at least 2015."
  )
})

test_that("validate_arguments() rejects a value over the maximum", {
  expect_error(
    validate_arguments(
      list(
        share = 1.5
      ),
      type_object(
        share = type_number(
          max = 1
        )
      )$schema
    ),
    "Argument `share` must be at most 1."
  )
})
