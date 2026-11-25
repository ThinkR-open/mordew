test_that("add_tool() creates a file defining the tool", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_tool(
    "summarise_runs",
    pkg = path
  )

  env <- new.env()
  sys.source(
    file.path(
      path,
      "R",
      "tool_summarise_runs.R"
    ),
    envir = env
  )
  expect_true(
    is.function(
      env$summarise_runs
    )
  )
})

test_that("add_tool() creates the test file of the tool", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_tool(
    "summarise_runs",
    pkg = path
  )

  expect_match(
    readLines(
      file.path(
        path,
        "tests",
        "testthat",
        "test-tool_summarise_runs.R"
      )
    ),
    "summarise_runs",
    all = FALSE
  )
})

test_that("add_tool() snapshots the schema of the tool in its tests", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_tool(
    "summarise_runs",
    pkg = path
  )

  expect_match(
    paste(
      readLines(
        file.path(
          path,
          "tests",
          "testthat",
          "test-tool_summarise_runs.R"
        )
      ),
      collapse = "\n"
    ),
    'mordew::expect_tool_schema\\(\\s*"summarise_runs"'
  )
})

test_that("add_tool() tests the tool against extreme arguments", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_tool(
    "summarise_runs",
    pkg = path
  )

  expect_match(
    paste(
      readLines(
        file.path(
          path,
          "tests",
          "testthat",
          "test-tool_summarise_runs.R"
        )
      ),
      collapse = "\n"
    ),
    'mordew::expect_hostile_safe\\(\\s*"summarise_runs"'
  )
})

test_that("add_tool() refuses an existing tool", {
  path <- tempfile()
  create_mordew(
    path
  )
  add_tool(
    "summarise_runs",
    pkg = path
  )

  expect_error(
    add_tool(
      "summarise_runs",
      pkg = path
    ),
    "already exists"
  )
})

test_that("add_tool() adds a tool the registry roclet registers", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  add_tool(
    "summarise_runs",
    pkg = path
  )
  suppressMessages(
    roxygen2::roxygenise(
      path,
      load_code = "source"
    )
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

  expect_named(
    env$mordew_registry,
    "summarise_runs"
  )
})
