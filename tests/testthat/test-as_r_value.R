test_that("as_r_value() turns an array of scalars into a vector", {
  expect_identical(
    as_r_value(
      list(
        "road",
        "trail"
      ),
      type_array(
        type_string()
      )$schema
    ),
    c(
      "road",
      "trail"
    )
  )
})

test_that("as_r_value() turns an empty array into an empty vector of its type", {
  expect_identical(
    as_r_value(
      list(),
      type_array(
        type_boolean()
      )$schema
    ),
    logical()
  )
})

test_that("as_r_value() turns an integer into an R integer", {
  expect_identical(
    as_r_value(
      2023,
      type_integer()$schema
    ),
    2023L
  )
})

test_that("as_r_value() turns a number into a double", {
  expect_identical(
    as_r_value(
      3L,
      type_number()$schema
    ),
    3
  )
})

test_that("as_r_value() converts the fields of an object", {
  expect_identical(
    as_r_value(
      list(
        year = 2023,
        surfaces = list(
          "road"
        )
      ),
      type_object(
        year = type_integer(),
        surfaces = type_array(
          type_string()
        )
      )$schema
    ),
    list(
      year = 2023L,
      surfaces = "road"
    )
  )
})

test_that("as_r_value() keeps an array of objects as a list", {
  expect_identical(
    as_r_value(
      list(
        list(
          year = 2023
        )
      ),
      type_array(
        type_object(
          year = type_integer()
        )
      )$schema
    ),
    list(
      list(
        year = 2023L
      )
    )
  )
})
