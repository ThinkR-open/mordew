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

test_that("validate_arguments() rejects a string not matching the pattern", {
  expect_error(
    validate_arguments(
      list(
        zip = "7500"
      ),
      type_object(
        zip = type_string(
          pattern = "^[0-9]{5}$"
        )
      )$schema
    ),
    "Argument `zip` must match the pattern ^[0-9]{5}$.",
    fixed = TRUE
  )
})

test_that("validate_arguments() reads the pattern as ECMA-262 does", {
  expect_no_error(
    validate_arguments(
      list(
        date = "2023-04-01"
      ),
      type_object(
        date = type_string(
          pattern = "^[\\d-]+$"
        )
      )$schema
    )
  )
})

test_that("validate_arguments() checks each item of an array", {
  expect_error(
    validate_arguments(
      list(
        surfaces = list(
          "road",
          12
        )
      ),
      type_object(
        surfaces = type_array(
          type_string()
        )
      )$schema
    ),
    "Argument `surfaces[1]` must be of type string.",
    fixed = TRUE
  )
})

test_that("validate_arguments() checks each field of a nested object", {
  expect_error(
    validate_arguments(
      list(
        period = list(
          year = "2023"
        )
      ),
      type_object(
        period = type_object(
          year = type_integer()
        )
      )$schema
    ),
    "Argument `period.year` must be of type integer.",
    fixed = TRUE
  )
})

test_that("validate_arguments() rejects a missing field of a nested object", {
  expect_error(
    validate_arguments(
      list(
        period = list(
          month = 4
        )
      ),
      type_object(
        period = type_object(
          year = type_integer(),
          month = type_integer(
            required = FALSE
          )
        )
      )$schema
    ),
    "Missing argument `period.year`.",
    fixed = TRUE
  )
})

test_that("validate_arguments() rejects an integer beyond the R integer range", {
  expect_error(
    validate_arguments(
      list(
        steps = 3e9
      ),
      type_object(
        steps = type_integer()
      )$schema
    ),
    "Argument `steps` must be of type integer."
  )
})

test_that("validate_arguments() names the fields of a result when asked", {
  schema <- type_object(
    runs = type_integer(),
    distance = type_number()
  )$schema

  expect_error(
    validate_arguments(
      list(
        runs = "twelve",
        distance = 84.5
      ),
      schema,
      "field"
    ),
    "Field `runs` must be of type integer.",
    fixed = TRUE
  )
  expect_error(
    validate_arguments(
      list(
        runs = 12
      ),
      schema,
      "field"
    ),
    "Missing field `distance`.",
    fixed = TRUE
  )
})
