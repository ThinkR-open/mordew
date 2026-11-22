test_that("server_identity() reads the identity of an installed package", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  writeLines(
    c(
      "Answers questions about a running log.",
      "Use summarise_runs for yearly volume."
    ),
    file.path(
      path,
      "inst",
      "mordew",
      "instructions.md"
    )
  )
  lib <- tempfile()
  dir.create(
    lib
  )
  utils::install.packages(
    path,
    repos = NULL,
    type = "source",
    lib = lib,
    quiet = TRUE
  )
  withr::local_libpaths(
    lib,
    action = "prefix"
  )

  expect_equal(
    server_identity(
      "runlog"
    ),
    list(
      name = "runlog",
      version = read.dcf(
        file.path(
          path,
          "DESCRIPTION"
        ),
        "Version"
      )[[1]],
      instructions = paste0(
        "Answers questions about a running log.\n",
        "Use summarise_runs for yearly volume."
      )
    )
  )
})
