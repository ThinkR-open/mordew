test_that("mordewtool works", {
  fail(
    "Write a test for mordewtool()."
  )
})

test_that("mordewtool is exposed with a stable schema", {
  mordew::expect_tool_schema(
    "mordewtool"
  )
})

test_that("mordewtool answers extreme arguments", {
  skip_on_cran()
  mordew::expect_hostile_safe(
    "mordewtool",
    list()
  )
})
