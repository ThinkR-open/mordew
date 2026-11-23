test_that("a tagged function becomes a tool named after it", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool
      summarise_runs <- function() NULL
      "
    ),
    list(
      summarise_runs = list(
        fun = "summarise_runs",
        tool = list(
          name = "summarise_runs"
        )
      )
    )
  )
})

test_that("@mcpTool can rename the tool", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool run_summary
      summarise_runs <- function() NULL
      "
    )$run_summary,
    list(
      fun = "summarise_runs",
      tool = list(
        name = "run_summary"
      )
    )
  )
})

test_that("an invalid tool name is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool run/summary
      summarise_runs <- function() NULL
      "
    ),
    "run/summary"
  )
})

test_that("a function without @mcpTool is not a tool", {
  expect_named(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool
      summarise_runs <- function() NULL

      #' Helper
      helper <- function() NULL
      "
    ),
    "summarise_runs"
  )
})

test_that("two tools with the same name are an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool summary
      summarise_runs <- function() NULL

      #' Summarise races
      #' @mcpTool summary
      summarise_races <- function() NULL
      "
    ),
    "Two tools are named `summary`."
  )
})
