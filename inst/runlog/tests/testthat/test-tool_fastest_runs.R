test_that("fastest_runs works", {
  fail(
    "Write a test for fastest_runs()."
  )
})

test_that("fastest_runs is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "fastest_runs"
  )
})

test_that("fastest_runs answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "fastest_runs",
    list()
  )
})
