test_that("call_matches() accepts the expected tool", {
  expect_true(
    call_matches(
      tool_call(
        "fastest_runs",
        n = 5
      ),
      tool_call(
        "fastest_runs",
        n = 5
      )
    )
  )
})

test_that("call_matches() rejects another tool", {
  expect_false(
    call_matches(
      tool_call(
        "fastest_runs",
        n = 5
      ),
      tool_call(
        "longest_runs",
        n = 5
      )
    )
  )
})

test_that("call_matches() rejects other arguments", {
  expect_false(
    call_matches(
      tool_call(
        "fastest_runs",
        n = 5
      ),
      tool_call(
        "fastest_runs",
        n = 3
      )
    )
  )
})

test_that("call_matches() accepts a number read from JSON as an integer", {
  expect_true(
    call_matches(
      tool_call(
        "fastest_runs",
        n = 5
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
      tool_call(
        "fastest_runs",
        n = 3,
        type = "interval"
      ),
      tool_call(
        "fastest_runs",
        type = "interval",
        n = 3
      )
    )
  )
})

test_that("call_matches() accepts part of a partial() argument", {
  expect_true(
    call_matches(
      tool_call(
        "get_race",
        name = partial(
          "Trail des Monts"
        )
      ),
      tool_call(
        "get_race",
        name = "monts"
      )
    )
  )
})

test_that("call_matches() rejects a value that is not part of a partial() argument", {
  expect_false(
    call_matches(
      tool_call(
        "get_race",
        name = partial(
          "Trail des Monts"
        )
      ),
      tool_call(
        "get_race",
        name = "lacs"
      )
    )
  )
})

test_that("call_matches() rejects an empty value for a partial() argument", {
  expect_false(
    call_matches(
      tool_call(
        "get_race",
        name = partial(
          "Trail des Monts"
        )
      ),
      tool_call(
        "get_race",
        name = ""
      )
    )
  )
})
