test_that("summarise_runs works", {
  fail(
    "Write a test for summarise_runs()."
  )
})

test_that("summarise_runs is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "summarise_runs"
  )
})

test_that("summarise_runs answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "summarise_runs",
    list()
  )
})
