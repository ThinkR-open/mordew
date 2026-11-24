test_that("call_tool() calls a tool of the installed package over stdio", {
  skip_if_not_installed(
    "processx"
  )
  local_install(
    local_tool_package()
  )

  expect_equal(
    call_tool(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "trail"
        )
      ),
      isError = FALSE
    )
  )
})

test_that("call_tool() serves the development version of a package loaded from source", {
  skip_if_not_installed(
    "processx"
  )
  path <- local_tool_package()
  tools <- file.path(
    path,
    "R",
    "tools.R"
  )
  writeLines(
    sub(
      "^  text$",
      "  toupper(text)",
      readLines(
        tools
      )
    ),
    tools
  )
  local_dev_package(
    path
  )

  expect_equal(
    call_tool(
      "echo",
      list(
        text = "road"
      ),
      package = "runlog"
    )$content[[1]]$text,
    "ROAD"
  )
})

test_that("call_tool() fails on a protocol error", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_error(
    call_tool(
      "nope",
      package = "runlog"
    ),
    "Unknown tool: nope"
  )
})
