test_that("check_tools() reports the functions that call a denied function", {
  path <- local_runlog()
  writeLines(
    c(
      "grep_runs <- function(pattern) {",
      "  system(paste(\"grep\", pattern, \"runs.csv\"))",
      "}"
    ),
    file.path(
      path,
      "R",
      "grep_runs.R"
    )
  )
  local_dev_package(
    path
  )

  expect_identical(
    check_tools(
      "runlog"
    ),
    "grep_runs() calls system()"
  )
})

test_that("check_tools() reports nothing for safe functions", {
  local_dev_package()

  expect_identical(
    check_tools(
      "runlog"
    ),
    character()
  )
})
