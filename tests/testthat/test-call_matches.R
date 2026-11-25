test_that("call_matches() accepts the expected tool", {
  expect_true(
    call_matches(
      list(
        tool = "fastest_runs",
        args = list(
          n = 5
        )
      ),
      list(
        tool = "fastest_runs",
        args = list(
          n = 5
        )
      )
    )
  )
})

test_that("call_matches() rejects another tool", {
  expect_false(
    call_matches(
      list(
        tool = "fastest_runs",
        args = list(
          n = 5
        )
      ),
      list(
        tool = "longest_runs",
        args = list(
          n = 5
        )
      )
    )
  )
})

test_that("call_matches() rejects other arguments", {
  expect_false(
    call_matches(
      list(
        tool = "fastest_runs",
        args = list(
          n = 5
        )
      ),
      list(
        tool = "fastest_runs",
        args = list(
          n = 3
        )
      )
    )
  )
})

test_that("call_matches() accepts a number read from JSON as an integer", {
  expect_true(
    call_matches(
      list(
        tool = "fastest_runs",
        args = list(
          n = 5
        )
      ),
      list(
        tool = "fastest_runs",
        args = jsonlite::fromJSON(
          '{"n": 5}',
          simplifyVector = FALSE
        )
      )
    )
  )
})

test_that("call_matches() ignores the order of the arguments", {
  expect_true(
    call_matches(
      list(
        tool = "fastest_runs",
        args = list(
          n = 3,
          type = "interval"
        )
      ),
      list(
        tool = "fastest_runs",
        args = list(
          type = "interval",
          n = 3
        )
      )
    )
  )
})

test_that("call_matches() accepts part of a partial() argument", {
  expect_true(
    call_matches(
      list(
        tool = "get_race",
        args = list(
          name = partial(
            "Trail des Monts"
          )
        )
      ),
      list(
        tool = "get_race",
        args = list(
          name = "monts"
        )
      )
    )
  )
})

test_that("call_matches() rejects a value that is not part of a partial() argument", {
  expect_false(
    call_matches(
      list(
        tool = "get_race",
        args = list(
          name = partial(
            "Trail des Monts"
          )
        )
      ),
      list(
        tool = "get_race",
        args = list(
          name = "lacs"
        )
      )
    )
  )
})

test_that("call_matches() rejects an empty value for a partial() argument", {
  expect_false(
    call_matches(
      list(
        tool = "get_race",
        args = list(
          name = partial(
            "Trail des Monts"
          )
        )
      ),
      list(
        tool = "get_race",
        args = list(
          name = ""
        )
      )
    )
  )
})
