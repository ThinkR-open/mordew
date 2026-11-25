test_that("case_passes() finds the expected call among all the calls", {
  expect_true(
    case_passes(
      list(
        list(
          tool_call(
            "fastest_runs",
            n = 5
          )
        )
      ),
      list(
        tool_call(
          "get_runs",
          year = 2025
        ),
        tool_call(
          "fastest_runs",
          n = 5
        )
      )
    )
  )
})

test_that("case_passes() fails when no call is the expected one", {
  expect_false(
    case_passes(
      list(
        list(
          tool_call(
            "fastest_runs",
            n = 5
          )
        )
      ),
      list(
        tool_call(
          "longest_runs",
          n = 5
        )
      )
    )
  )
})

test_that("case_passes() accepts any of the answers", {
  expect_true(
    case_passes(
      list(
        list(
          tool_call(
            "summarise_runs",
            year = 2025
          )
        ),
        list(
          tool_call(
            "get_runs",
            year = 2025
          )
        )
      ),
      list(
        tool_call(
          "get_runs",
          year = 2025
        )
      )
    )
  )
})

test_that("case_passes() needs every call of an answer", {
  expect_false(
    case_passes(
      list(
        list(
          tool_call(
            "summarise_runs",
            year = 2024
          ),
          tool_call(
            "summarise_runs",
            year = 2025
          )
        )
      ),
      list(
        tool_call(
          "summarise_runs",
          year = 2024
        )
      )
    )
  )
})

test_that("case_passes() expects no call when there is no answer", {
  expect_true(
    case_passes(
      list(),
      list()
    )
  )
  expect_false(
    case_passes(
      list(),
      list(
        tool_call(
          "get_runs"
        )
      )
    )
  )
})
