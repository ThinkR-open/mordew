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
      resources = list(),
      prompts = list()
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
      "mordew_resources <- list()",
      "",
      "mordew_prompts <- list()"
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
        ),
        returns = "text"
      )
    )
  )
})

test_that("a URI template becomes a resource template keyed by it", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Runs of a year
      #'
      #' The runs of one year.
      #' @mcpResource runlog://runs/{year}
      runs <- function(year) NULL
      "
    )$resources,
    list(
      "runlog://runs/{year}" = list(
        fun = "runs",
        resource = list(
          uriTemplate = "runlog://runs/{year}",
          name = "runs",
          title = "Runs of a year",
          description = "The runs of one year.",
          mimeType = "text/plain"
        ),
        returns = "text"
      )
    )
  )
})

test_that("the arguments of a resource must be the variables of its URI", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Runs of a year
      #'
      #' The runs of one year.
      #' @mcpResource runlog://runs/{year}
      runs <- function() NULL
      "
    ),
    "The arguments of `runs` must be the variables of `runlog://runs/{year}`.",
    fixed = TRUE
  )
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #'
      #' The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      surfaces <- function(type) NULL
      "
    ),
    "The arguments of `surfaces` must be the variables of `runlog://surfaces`.",
    fixed = TRUE
  )
})

test_that("a URI template variable other than {name} is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Runs of a year
      #'
      #' The runs of one year.
      #' @mcpResource runlog://runs{?year}
      runs <- function(year) NULL
      "
    ),
    "`runlog://runs{?year}`: `{?year}` is not supported, only `{name}` variables are.",
    fixed = TRUE
  )
})

test_that("@mcpReturns sets what a resource returns and its MIME type", {
  resource_kind <- function(
    returns
  ) {
    entry <- roxygen2::roc_proc_text(
      registry_roclet(),
      paste0(
        "
        #' Surfaces
        #'
        #' The surfaces a run can be on.
        #' @mcpResource runlog://surfaces
        #' @mcpReturns ",
        returns,
        "
        surfaces <- function() NULL
        "
      )
    )$resources[["runlog://surfaces"]]
    c(
      entry$returns,
      entry$resource$mimeType
    )
  }

  expect_identical(
    resource_kind(
      "text"
    ),
    c(
      "text",
      "text/plain"
    )
  )
  expect_identical(
    resource_kind(
      "table"
    ),
    c(
      "table",
      "text/markdown"
    )
  )
  expect_identical(
    resource_kind(
      "json"
    ),
    c(
      "json",
      "application/json"
    )
  )
  expect_identical(
    resource_kind(
      "image"
    ),
    c(
      "image",
      "image/png"
    )
  )
})

test_that("an unknown return kind of a resource is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #'
      #' The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      #' @mcpReturns csv
      surfaces <- function() NULL
      "
    ),
    "`surfaces` needs `@mcpReturns` text, table, image or json."
  )
})

test_that("a resource without title is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' @description The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      surfaces <- function() NULL
      "
    ),
    "`surfaces` has no title"
  )
})

test_that("a resource without description is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #' @mcpResource runlog://surfaces
      surfaces <- function() NULL
      "
    ),
    "`surfaces` has no description: clients use it to tell the model what the resource holds."
  )
})

test_that("a resource tag on an object that is not a function is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #'
      #' The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      surfaces <- 'road, trail, track'
      "
    ),
    "`surfaces` is not a function: only a function can be a resource."
  )
})

test_that("two resources with the same URI are an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Surfaces
      #'
      #' The surfaces a run can be on.
      #' @mcpResource runlog://surfaces
      surfaces <- function() NULL

      #' Terrains
      #'
      #' The terrains a run can be on.
      #' @mcpResource runlog://surfaces
      terrains <- function() NULL
      "
    ),
    "Two resources have the URI `runlog://surfaces`."
  )
})

test_that("a function tagged @mcpPrompt becomes a prompt named after it", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @param run_id ID of the run.
      #' @param tone Tone of the review.
      #' @mcpPrompt
      review_run <- function(run_id, tone = 'kind') NULL
      "
    )$prompts,
    list(
      review_run = list(
        fun = "review_run",
        prompt = list(
          name = "review_run",
          title = "Review a run",
          description = "Asks for a review of one run.",
          arguments = list(
            list(
              name = "run_id",
              description = "ID of the run.",
              required = TRUE
            ),
            list(
              name = "tone",
              description = "Tone of the review.",
              required = FALSE
            )
          )
        )
      )
    )
  )
})

test_that("a prompt argument without @param is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @mcpPrompt
      review_run <- function(run_id) NULL
      "
    ),
    "`review_run`: parameter `run_id` has no `@param`."
  )
})

test_that("a prompt without description is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #' @mcpPrompt
      review_run <- function() NULL
      "
    ),
    "`review_run` has no description: clients show it to users to pick the prompt."
  )
})

test_that("a prompt tag on an object that is not a function is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @mcpPrompt
      review_run <- 'Review the run.'
      "
    ),
    "`review_run` is not a function: only a function can be a prompt."
  )
})

test_that("two prompts with the same name are an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @mcpPrompt
      review_run <- function() NULL

      #' Review a run again
      #'
      #' Asks for a second review of one run.
      #' @mcpPrompt
      review_run <- function() NULL
      "
    ),
    "Two prompts are named `review_run`."
  )
})

test_that("the written registry sources back the prompts", {
  prompts <- list(
    review_run = list(
      fun = "review_run",
      prompt = list(
        name = "review_run",
        arguments = list()
      )
    )
  )
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
      tools = list(),
      resources = list(),
      prompts = prompts
    ),
    base_path = path
  )
  env <- new.env()
  sys.source(
    file.path(
      path,
      "R",
      "mordew_registry.R"
    ),
    envir = env
  )

  expect_equal(
    env$mordew_prompts,
    prompts
  )
})

test_that("@mcpComplete links an argument of a prompt to its completion function", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @param run_id ID of the run.
      #' @mcpPrompt
      #' @mcpComplete run_id complete_run_ids
      review_run <- function(run_id) NULL
      "
    )$prompts$review_run$complete,
    list(
      run_id = "complete_run_ids"
    )
  )
})

test_that("@mcpComplete links a variable of a resource template to its completion function", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Runs of a year
      #'
      #' The runs of one year.
      #' @mcpResource runlog://runs/{year}
      #' @mcpComplete year complete_years
      runs <- function(year) NULL
      "
    )$resources[["runlog://runs/{year}"]]$complete,
    list(
      year = "complete_years"
    )
  )
})

test_that("an @mcpComplete naming no argument is an error", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @param run_id ID of the run.
      #' @mcpPrompt
      #' @mcpComplete distance complete_distances
      review_run <- function(run_id) NULL
      "
    ),
    "`review_run`: `@mcpComplete distance` names no argument."
  )
})

test_that("@mcpComplete needs an argument and a function", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Review a run
      #'
      #' Asks for a review of one run.
      #' @param run_id ID of the run.
      #' @mcpPrompt
      #' @mcpComplete run_id
      review_run <- function(run_id) NULL
      "
    ),
    "`review_run` needs `@mcpComplete <argument> <function>`."
  )
})

test_that("@mcpOutput sets the output schema of a tool", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Year summary
      #'
      #' Totals of one year.
      #' @mcpTool
      #' @mcpReturns json
      #' @mcpOutput type_object(runs = type_integer(), distance = type_number())
      summarise_runs <- function() NULL
      "
    )$tools$summarise_runs$tool$outputSchema,
    type_object(
      runs = type_integer(),
      distance = type_number()
    )$schema
  )
})

test_that("an @mcpOutput that is not an object type is an error", {
  output_error <- function(
    output
  ) {
    expect_error(
      roxygen2::roc_proc_text(
        registry_roclet(),
        paste0(
          "
          #' Year summary
          #'
          #' Totals of one year.
          #' @mcpTool
          #' @mcpReturns json
          #' @mcpOutput ",
          output,
          "
          summarise_runs <- function() NULL
          "
        )
      ),
      "`summarise_runs`: `@mcpOutput` must be a type_object().",
      fixed = TRUE
    )
  }

  output_error(
    "type_string()"
  )
  output_error(
    "42"
  )
})

test_that("@mcpOutput needs @mcpReturns json", {
  expect_error(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Year summary
      #'
      #' Totals of one year.
      #' @mcpTool
      #' @mcpReturns table
      #' @mcpOutput type_object(runs = type_integer())
      summarise_runs <- function() NULL
      "
    ),
    "`summarise_runs` has an `@mcpOutput`: it needs `@mcpReturns json`."
  )
})


test_that("@mcpIcon gives a tool its icons", {
  expect_equal(
    roxygen2::roc_proc_text(
      registry_roclet(),
      "
      #' Year summary
      #'
      #' Totals of one year.
      #' @mcpTool
      #' @mcpReturns text
      #' @mcpIcon https://example.org/run.png mimeType=image/png sizes=48x48,96x96 theme=dark
      #' @mcpIcon data:image/svg+xml;base64,PHN2Zz4= sizes=any
      summarise_runs <- function() NULL
      "
    )$tools$summarise_runs$tool$icons,
    list(
      list(
        src = "https://example.org/run.png",
        mimeType = "image/png",
        sizes = list(
          "48x48",
          "96x96"
        ),
        theme = "dark"
      ),
      list(
        src = "data:image/svg+xml;base64,PHN2Zz4=",
        sizes = list(
          "any"
        )
      )
    )
  )
})

test_that("@mcpIcon gives resources and prompts their icons", {
  registry <- roxygen2::roc_proc_text(
    registry_roclet(),
    "
    #' Surfaces
    #'
    #' The surfaces a run can be on.
    #' @mcpResource runlog://surfaces
    #' @mcpIcon https://example.org/surfaces.png
    surfaces <- function() NULL

    #' Review a run
    #'
    #' Asks for a review of one run.
    #' @mcpPrompt
    #' @mcpIcon https://example.org/review.png
    review_run <- function() NULL
    "
  )

  expect_equal(
    list(
      registry$resources[["runlog://surfaces"]]$resource$icons,
      registry$prompts$review_run$prompt$icons
    ),
    list(
      list(
        list(
          src = "https://example.org/surfaces.png"
        )
      ),
      list(
        list(
          src = "https://example.org/review.png"
        )
      )
    )
  )
})

test_that("an @mcpIcon that the specification does not allow is an error", {
  icon_error <- function(
    icon,
    message
  ) {
    expect_error(
      roxygen2::roc_proc_text(
        registry_roclet(),
        paste0(
          "
          #' Year summary
          #'
          #' Totals of one year.
          #' @mcpTool
          #' @mcpReturns text
          #' @mcpIcon ",
          icon,
          "
          summarise_runs <- function() NULL
          "
        )
      ),
      message,
      fixed = TRUE
    )
  }

  icon_error(
    "ftp://example.org/run.png",
    "`summarise_runs`: an icon needs an http, https or data URI, not `ftp://example.org/run.png`."
  )
  icon_error(
    "https://example.org/run.png color=red",
    "`summarise_runs`: `@mcpIcon` takes mimeType=, sizes= and theme=, not `color=red`."
  )
  icon_error(
    "https://example.org/run.png sizes=48",
    "`summarise_runs`: icon sizes are WxH or any, not `48`."
  )
  icon_error(
    "https://example.org/run.png theme=blue",
    "`summarise_runs`: an icon theme is light or dark, not `blue`."
  )
})
