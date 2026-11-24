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
  local_install(
    path
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

test_that("server_identity() refuses a package without instructions", {
  path <- local_dev_package()
  unlink(
    file.path(
      path,
      "inst",
      "mordew",
      "instructions.md"
    )
  )

  expect_error(
    server_identity(
      "runlog"
    ),
    "`runlog` has no inst/mordew/instructions.md."
  )
})
