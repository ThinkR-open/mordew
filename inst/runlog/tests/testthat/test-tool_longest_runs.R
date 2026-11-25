test_that("longest_runs works", {
  fail(
    "Write a test for longest_runs()."
  )
})

test_that("longest_runs is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "longest_runs"
  )
})

test_that("longest_runs answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "longest_runs",
    list()
  )
})
