test_that("create_mordew() names the package after the path", {
  path <- file.path(
    tempfile(),
    "runlog"
  )

  create_mordew(
    path
  )

  expect_equal(
    read.dcf(
      file.path(
        path,
        "DESCRIPTION"
      ),
      "Package"
    )[[1]],
    "runlog"
  )
})

test_that("create_mordew() refuses an existing path", {
  path <- tempfile()
  dir.create(
    path
  )

  expect_error(
    create_mordew(
      path
    ),
    "already exists"
  )
})

test_that("create_mordew(overwrite = TRUE) replaces an existing path", {
  path <- tempfile()
  dir.create(
    path
  )
  file.create(
    file.path(
      path,
      "old.R"
    )
  )

  create_mordew(
    path,
    overwrite = TRUE
  )

  expect_false(
    file.exists(
      file.path(
        path,
        "old.R"
      )
    )
  )
})

test_that("create_mordew() adds the server instructions", {
  path <- tempfile()

  create_mordew(
    path
  )

  expect_true(
    file.exists(
      file.path(
        path,
        "inst",
        "mordew",
        "instructions.md"
      )
    )
  )
})

test_that("create_mordew() adds the dev scripts", {
  path <- tempfile()

  create_mordew(
    path
  )

  expect_setequal(
    list.files(
      file.path(
        path,
        "dev"
      )
    ),
    c(
      "01_start.R",
      "02_dev.R",
      "03_deploy.R"
    )
  )
})

test_that("create_mordew() keeps dev/ out of the build", {
  path <- tempfile()

  create_mordew(
    path
  )

  expect_contains(
    readLines(
      file.path(
        path,
        ".Rbuildignore"
      )
    ),
    "^dev$"
  )
})
