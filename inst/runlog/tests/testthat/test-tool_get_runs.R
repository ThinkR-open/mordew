test_that("get_runs works", {
  fail(
    "Write a test for get_runs()."
  )
})

test_that("get_runs is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "get_runs"
  )
})

test_that("get_runs answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "get_runs",
    list()
  )
})
