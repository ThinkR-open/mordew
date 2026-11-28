test_that("add_prompt() creates a file defining the prompt", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_prompt(
    "review_run",
    pkg = path
  )

  env <- new.env()
  sys.source(
    file.path(
      path,
      "R",
      "prompt_review_run.R"
    ),
    envir = env
  )
  expect_true(
    is.function(
      env$review_run
    )
  )
})

test_that("add_prompt() adds a prompt that the roclet registers", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  add_prompt(
    "review_run",
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
    env$mordew_prompts,
    "review_run"
  )
})

test_that("add_prompt() writes the text of the prompt, which the prompt reads", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  add_prompt(
    "review_run",
    pkg = path
  )
  local_dev_package(
    path
  )

  expect_identical(
    asNamespace(
      "runlog"
    )$review_run(),
    readLines(
      file.path(
        path,
        "inst",
        "mordew",
        "prompts",
        "review_run.md"
      )
    )
  )
})

test_that("add_prompt() gets the prompt through an MCP client in its tests", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_prompt(
    "review_run",
    pkg = path
  )

  expect_match(
    paste(
      readLines(
        file.path(
          path,
          "tests",
          "testthat",
          "test-prompt_review_run.R"
        )
      ),
      collapse = "\n"
    ),
    'mordew::expect_prompt\\(\\s*"review_run"'
  )
})

test_that("add_prompt() refuses an existing prompt", {
  path <- tempfile()
  create_mordew(
    path
  )
  add_prompt(
    "review_run",
    pkg = path
  )

  expect_error(
    add_prompt(
      "review_run",
      pkg = path
    ),
    "already exists"
  )
})
