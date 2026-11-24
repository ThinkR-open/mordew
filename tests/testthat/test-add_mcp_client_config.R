test_that("add_mcp_client_config() writes the Claude Code configuration at the package root", {
  path <- local_runlog()

  add_mcp_client_config(
    path
  )

  expect_equal(
    paste(
      readLines(
        file.path(
          path,
          "runlog.json"
        )
      ),
      collapse = "\n"
    ),
    server_json()
  )
})

test_that("add_mcp_client_config() keeps the configuration out of the build, once", {
  path <- local_runlog()

  add_mcp_client_config(
    path
  )
  add_mcp_client_config(
    path,
    overwrite = TRUE
  )

  expect_equal(
    readLines(
      file.path(
        path,
        ".Rbuildignore"
      )
    ),
    c(
      "^dev$",
      "^runlog\\.json$"
    )
  )
})

test_that("add_mcp_client_config() refuses to replace an existing file", {
  path <- local_runlog()
  add_mcp_client_config(
    path
  )

  expect_error(
    add_mcp_client_config(
      path
    ),
    "runlog.json already exists. Use `overwrite = TRUE` to replace it.",
    fixed = TRUE
  )
})

test_that("add_mcp_client_config() keeps the configuration out of git, once", {
  path <- local_runlog()

  add_mcp_client_config(
    path
  )
  add_mcp_client_config(
    path,
    overwrite = TRUE
  )

  expect_equal(
    readLines(
      file.path(
        path,
        ".gitignore"
      )
    ),
    "/runlog.json"
  )
})
