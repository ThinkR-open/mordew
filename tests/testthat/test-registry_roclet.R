test_that("a tagged function becomes a tool named after it", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      summarise_runs <- function() NULL
      "
    ),
    list(
      summarise_runs = list(
        fun = "summarise_runs",
        tool = list(
          name = "summarise_runs",
          title = "Summarise runs",
          description = "Number of runs per year."
        ),
        returns = "text"
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
      #'
      #' Number of runs per year.
      #' @mcpTool run_summary
      #' @mcpReturns text
      summarise_runs <- function() NULL
      "
    )$run_summary,
    list(
      fun = "summarise_runs",
      tool = list(
        name = "run_summary",
        title = "Summarise runs",
        description = "Number of runs per year."
      ),
      returns = "text"
    )
  )
})

test_that("an invalid tool name is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool run/summary
      #' @mcpReturns text
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
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
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
      #'
      #' Number of runs per year.
      #' @mcpTool summary
      #' @mcpReturns text
      summarise_runs <- function() NULL

      #' Summarise races
      #'
      #' Number of races per year.
      #' @mcpTool summary
      #' @mcpReturns text
      summarise_races <- function() NULL
      "
    ),
    "Two tools are named `summary`."
  )
})

test_that("the title and description keep their markdown", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise `runs`
      #'
      #' Number of `runs` per year.
      #' @mcpTool
      #' @mcpReturns text
      #' @md
      summarise_runs <- function() NULL
      "
    )$summarise_runs$tool[
      c(
        "title",
        "description"
      )
    ],
    list(
      title = "Summarise `runs`",
      description = "Number of `runs` per year."
    )
  )
})

test_that("a tool without description is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #' @mcpTool
      #' @mcpReturns text
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` has no description"
  )
})

test_that("@mcpReturns sets what the tool returns", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns table
      summarise_runs <- function() NULL
      "
    )$summarise_runs$returns,
    "table"
  )
})

test_that("a tool without @mcpReturns is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` needs `@mcpReturns` text, table, image or json."
  )
})

test_that("an unknown return kind is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns csv
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` needs `@mcpReturns` text, table, image or json."
  )
})
