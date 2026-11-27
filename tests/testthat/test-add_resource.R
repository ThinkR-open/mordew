test_that("add_resource() creates a file defining the resource", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_resource(
    "surfaces",
    pkg = path
  )

  env <- new.env()
  sys.source(
    file.path(
      path,
      "R",
      "resource_surfaces.R"
    ),
    envir = env
  )
  expect_true(
    is.function(
      env$surfaces
    )
  )
})

test_that("add_resource() adds a resource under the package's name that the roclet registers", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  add_resource(
    "surfaces",
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
    env$mordew_resources,
    "runlog://surfaces"
  )
})

test_that("add_resource() creates the test file of the resource", {
  path <- tempfile()
  create_mordew(
    path
  )

  add_resource(
    "surfaces",
    pkg = path
  )

  expect_match(
    readLines(
      file.path(
        path,
        "tests",
        "testthat",
        "test-resource_surfaces.R"
      )
    ),
    "surfaces",
    all = FALSE
  )
})

test_that("add_resource() refuses an existing resource", {
  path <- tempfile()
  create_mordew(
    path
  )
  add_resource(
    "surfaces",
    pkg = path
  )

  expect_error(
    add_resource(
      "surfaces",
      pkg = path
    ),
    "already exists"
  )
})

test_that("add_resource() refuses a name that is not syntactic before writing", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )

  expect_error(
    add_resource(
      "my-resource",
      pkg = path
    ),
    "`my-resource` is not a syntactic name",
    fixed = TRUE
  )
  expect_false(
    file.exists(
      file.path(
        path,
        "R",
        "resource_my-resource.R"
      )
    )
  )
})
