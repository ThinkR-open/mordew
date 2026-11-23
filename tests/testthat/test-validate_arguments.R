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
