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
    )$tools,
    list(
      summarise_runs = list(
        fun = "summarise_runs",
        tool = list(
          name = "summarise_runs",
          title = "Summarise runs",
          description = "Number of runs per year.",
          inputSchema = list(
            type = "object",
            additionalProperties = FALSE
          )
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
    )$tools$run_summary,
    list(
      fun = "summarise_runs",
      tool = list(
        name = "run_summary",
        title = "Summarise runs",
        description = "Number of runs per year.",
        inputSchema = list(
          type = "object",
          additionalProperties = FALSE
        )
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
    )$tools,
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
    )$tools$summarise_runs$tool[
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
    )$tools$summarise_runs$returns,
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

write_registry <- function(
  registry
) {
  path <- tempfile()
  dir.create(
    file.path(
      path,
      "R"
    ),
    recursive = TRUE
  )
  roxygen2::roclet_output(
    registry_roclet(),
    list(
      tools = registry,
      resources = list()
    ),
    base_path = path
  )
  file.path(
    path,
    "R",
    "mordew_registry.R"
  )
}

test_that("the registry is written one element per line", {
  expect_equal(
    readLines(
      write_registry(
        list(
          summarise_runs = list(
            fun = "summarise_runs",
            returns = "text"
          )
        )
      )
    ),
    c(
      "# Generated by mordew: do not edit by hand.",
      "",
      "mordew_registry <- list(",
      "  summarise_runs = list(",
      "    fun = \"summarise_runs\",",
      "    returns = \"text\"",
      "  )",
      ")",
      "",
      "mordew_resources <- list()"
    )
  )
})

test_that("the written registry sources back to the same list", {
  registry <- list(
    summarise_runs = list(
      fun = "summarise_runs",
      tool = list(
        name = "summarise_runs",
        title = "Summarise `runs`",
        description = "Number of \"runs\".\nPer year."
      ),
      returns = "text"
    )
  )
  env <- new.env()
  sys.source(
    write_registry(
      registry
    ),
    envir = env
  )
  expect_equal(
    env$mordew_registry,
    registry
  )
})

test_that("a tool name that is not an R name is backquoted", {
  expect_contains(
    readLines(
      write_registry(
        list(
          `run-summary` = list(
            fun = "summarise_runs"
          )
        )
      )
    ),
    "  `run-summary` = list("
  )
})

test_that("a package without tools gets an empty registry", {
  expect_contains(
    readLines(
      write_registry(
        list()
      )
    ),
    "mordew_registry <- list()"
  )
})

test_that("annotation tags declare the safe side", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpClosedWorld
      #' @mcpReadOnly
      summarise_runs <- function() NULL
      "
    )$tools$summarise_runs$tool$annotations,
    list(
      readOnlyHint = TRUE,
      openWorldHint = FALSE
    )
  )
})

test_that("redundant annotation tags next to @mcpReadOnly are accepted", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpReadOnly
      #' @mcpNonDestructive
      #' @mcpIdempotent
      summarise_runs <- function() NULL
      "
    )$tools$summarise_runs$tool$annotations,
    list(
      readOnlyHint = TRUE,
      destructiveHint = FALSE,
      idempotentHint = TRUE
    )
  )
})

test_that("a tool without annotation tags sends no annotations", {
  expect_false(
    "annotations" %in%
      names(
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
        )$tools$summarise_runs$tool
      )
  )
})

test_that("@mcpLimit rows caps the rows of a table tool", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns table
      #' @mcpLimit rows 500
      summarise_runs <- function() NULL
      "
    )$tools$summarise_runs$limit,
    list(
      rows = 500L
    )
  )
})

test_that("a tool without @mcpLimit has no limit", {
  expect_false(
    "limit" %in%
      names(
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
        )$tools$summarise_runs
      )
  )
})

test_that("a limit other than rows is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns table
      #' @mcpLimit seconds 10
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` needs `@mcpLimit rows <n>`, with n a positive integer."
  )
})

test_that("a row limit that is not a positive integer is an error", {
  for (n in c("0", "many")) {
    expect_error(
      roxygen2::roc_proc_text(
        registry_roclet(),
        paste0(
          "
          #' Summarise runs
          #'
          #' Number of runs per year.
          #' @mcpTool
          #' @mcpReturns table
          #' @mcpLimit rows ",
          n,
          "
          summarise_runs <- function() NULL
          "
        )
      ),
      "`summarise_runs` needs `@mcpLimit rows <n>`, with n a positive integer."
    )
  }
})

test_that("a row limit on a tool that does not return a table is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpLimit rows 500
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` returns text: `@mcpLimit rows` needs `@mcpReturns table`."
  )
})

test_that("@mcpType and @param build the inputSchema", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param surface Running surface.
      #' @param year Four-digit `year`.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType year type_integer(min = 2015)
      #' @mcpType surface type_enum(c(\"road\", \"trail\"))
      #' @md
      summarise_runs <- function(surface, year) NULL
      "
    )$tools$summarise_runs$tool$inputSchema,
    list(
      type = "object",
      properties = list(
        surface = list(
          type = "string",
          enum = list(
            "road",
            "trail"
          ),
          description = "Running surface."
        ),
        year = list(
          type = "integer",
          minimum = 2015,
          description = "Four-digit `year`."
        )
      ),
      required = list(
        "surface",
        "year"
      ),
      additionalProperties = FALSE
    )
  )
})

test_that("an @mcpType expression that is not a type is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType year integer
      summarise_runs <- function(year) NULL
      "
    ),
    "`summarise_runs`: `@mcpType year` is not a mordew type."
  )
})

test_that("a typed parameter without @param is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType year type_integer()
      summarise_runs <- function(year) NULL
      "
    ),
    "`summarise_runs`: parameter `year` has no `@param`."
  )
})

test_that("unnamed lists are written back as unnamed lists", {
  registry <- list(
    summarise_runs = list(
      required = list(
        "surface",
        "year"
      )
    )
  )
  env <- new.env()
  sys.source(
    write_registry(
      registry
    ),
    envir = env
  )
  expect_equal(
    env$mordew_registry,
    registry
  )
})

test_that("a parameter without @mcpType is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      summarise_runs <- function(year) NULL
      "
    ),
    "`summarise_runs`: parameter `year` has no `@mcpType`."
  )
})

test_that("an @mcpType naming no parameter is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType yaer type_integer()
      summarise_runs <- function(year) NULL
      "
    ),
    "`summarise_runs`: `@mcpType yaer` names no parameter."
  )
})

test_that("required = FALSE without a default value is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType year type_integer(required = FALSE)
      summarise_runs <- function(year) NULL
      "
    ),
    "`summarise_runs`: parameter `year` needs `required = FALSE` if and only if it has a default value."
  )
})

test_that("a default value without required = FALSE is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType year type_integer()
      summarise_runs <- function(year = 2024) NULL
      "
    ),
    "`summarise_runs`: parameter `year` needs `required = FALSE` if and only if it has a default value."
  )
})

test_that("a parameter with a default value and required = FALSE is optional", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #' @param surface Running surface.
      #' @param year Four-digit year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpType surface type_string()
      #' @mcpType year type_integer(required = FALSE)
      summarise_runs <- function(surface, year = 2024) NULL
      "
    )$tools$summarise_runs$tool$inputSchema$required,
    list(
      "surface"
    )
  )
})

test_that("a parameter description stops at its text", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Summarise runs
      #'
      #' Number of runs per year.
      #'
      #' @param year Four-digit year.
      #'
      #' @mcpTool
      #' @mcpType year type_integer()
      #' @mcpReturns text
      summarise_runs <- function(year) NULL
      "
    )$tools$summarise_runs$tool$inputSchema$properties$year$description,
    "Four-digit year."
  )
})

test_that("a tool without title is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' @description Number of runs per year.
      #' @mcpTool
      #' @mcpReturns text
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` has no title"
  )
})

test_that("a tool tag on an object that is not a function is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Runs
      #'
      #' Number of runs.
      #' @mcpTool
      #' @mcpReturns text
      runs <- 12
      "
    ),
    "`runs` is not a function"
  )
})

test_that("the registry is written in ASCII and sources back to the same strings", {
  registry <- list(
    summarise_runs = list(
      description = "Répète le texte \U0001f3c3."
    )
  )
  file <- write_registry(
    registry
  )
  env <- new.env()
  sys.source(
    file,
    envir = env
  )

  expect_true(
    all(
      utf8ToInt(
        paste(
          readLines(
            file,
            encoding = "UTF-8"
          ),
          collapse = ""
        )
      ) <
        128
    )
  )
  expect_identical(
    env$mordew_registry,
    registry
  )
})

test_that("a function tagged @mcpResource becomes a resource keyed by its URI", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #'
      #' The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      surfaces <- function() NULL
      "
    )$resources,
    list(
      "runlog://surfaces" = list(
        fun = "surfaces",
        resource = list(
          uri = "runlog://surfaces",
          name = "surfaces",
          title = "Surfaces",
          description = "The surfaces a run can be on.",
          mimeType = "text/plain"
        )
      )
    )
  )
})
