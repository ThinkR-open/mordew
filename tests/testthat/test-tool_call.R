test_that("tool_call() describes a call by its tool and its arguments", {
  expect_identical(
    tool_call(
      "fastest_runs",
      n = 3,
      type = "interval"
    ),
    list(
      tool = "fastest_runs",
      args = list(
        n = 3,
        type = "interval"
      )
    )
  )
})
