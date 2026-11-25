test_that("use_evals() writes a script that runs the evals of the package", {
  path <- tempfile()
  create_mordew(
    path
  )

  use_evals(
    pkg = path
  )

  expect_match(
    readLines(
      file.path(
        path,
        "dev",
        "evals.R"
      )
    ),
    "mordew::run_evals(",
    fixed = TRUE,
    all = FALSE
  )
})

test_that("use_evals() refuses an existing script", {
  path <- tempfile()
  create_mordew(
    path
  )
  use_evals(
    pkg = path
  )

  expect_error(
    use_evals(
      pkg = path
    ),
    "already exists"
  )
})

test_that("use_evals() writes a CI workflow that runs the script", {
  path <- tempfile()
  create_mordew(
    path
  )

  use_evals(
    pkg = path
  )

  expect_match(
    readLines(
      file.path(
        path,
        ".github",
        "workflows",
        "evals.yaml"
      )
    ),
    "Rscript dev/evals.R",
    fixed = TRUE,
    all = FALSE
  )
})
