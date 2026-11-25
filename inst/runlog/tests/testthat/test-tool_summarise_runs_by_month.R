test_that("summarise_runs_by_month works", {
  fail(
    "Write a test for summarise_runs_by_month()."
  )
})

test_that("summarise_runs_by_month is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "summarise_runs_by_month"
  )
})

test_that("summarise_runs_by_month answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "summarise_runs_by_month",
    list()
  )
})
