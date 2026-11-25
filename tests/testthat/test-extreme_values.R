test_that("extreme_values() gives an empty and a huge string for a free string", {
  expect_identical(
    extreme_values(
      type_string()$schema
    ),
    list(
      "",
      strrep(
        "a",
        1e5
      )
    )
  )
})

test_that("extreme_values() keeps the strings the pattern accepts", {
  expect_identical(
    extreme_values(
      type_string(
        pattern = "^[a-z]+$"
      )$schema
    ),
    list(
      strrep(
        "a",
        1e5
      )
    )
  )
})

test_that("extreme_values() gives nothing for an enum or a boolean", {
  expect_length(
    extreme_values(
      type_enum(
        c(
          "road",
          "trail"
        )
      )$schema
    ),
    0
  )
  expect_length(
    extreme_values(
      type_boolean()$schema
    ),
    0
  )
})

test_that("extreme_values() gives the largest integers an unbounded schema accepts", {
  expect_identical(
    extreme_values(
      type_integer()$schema
    ),
    list(
      .Machine$integer.max,
      -.Machine$integer.max
    )
  )
})

test_that("extreme_values() gives the bounds of a bounded integer", {
  expect_identical(
    extreme_values(
      type_integer(
        min = 1,
        max = 50
      )$schema
    ),
    list(
      1,
      50
    )
  )
})

test_that("extreme_values() gives the largest numbers within the bounds", {
  expect_identical(
    extreme_values(
      type_number(
        min = 0
      )$schema
    ),
    list(
      0,
      .Machine$double.xmax
    )
  )
})
