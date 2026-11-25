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

test_that("call_tool() reads the result of the MCP Inspector", {
  skip_on_os(
    "windows"
  )
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()
  local_fake_npx(
    withr::local_tempdir()
  )

  expect_identical(
    call_tool(
      "fastest_runs",
      list(
        n = 3,
        type = "interval"
      ),
      package = "runlog",
      client = "inspector"
    ),
    c(
      jsonlite::read_json(
        test_path(
          "fixtures",
          "inspector-call.json"
        )
      ),
      list(
        isError = FALSE
      )
    )
  )
})

test_that("call_tool() starts the server from the MCP Inspector", {
  skip_on_os(
    "windows"
  )
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()
  record <- withr::local_tempdir()
  local_fake_npx(
    record
  )

  call_tool(
    "fastest_runs",
    list(
      n = 3,
      type = "interval"
    ),
    package = "runlog",
    client = "inspector"
  )

  expect_identical(
    readLines(
      file.path(
        record,
        "args"
      )
    ),
    c(
      "-y",
      "@modelcontextprotocol/inspector@2.16.0",
      "--cli",
      "--method",
      "tools/call",
      "--tool-name",
      "fastest_runs",
      "--tool-args-json",
      '{"n":3,"type":"interval"}',
      "--",
      rscript(),
      server_args(
        "runlog",
        find.package(
          "runlog"
        )
      )
    )
  )
})

test_that("call_tool() stops with the error of the MCP Inspector", {
  skip_on_os(
    "windows"
  )
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()
  local_fake_npx(
    withr::local_tempdir(),
    output = NULL,
    stderr = '{"error":{"code":"tool_not_found","message":"Tool \'nope\' not found on server."}}',
    status = 5
  )

  expect_error(
    call_tool(
      "nope",
      package = "runlog",
      client = "inspector"
    ),
    "Tool 'nope' not found on server.",
    fixed = TRUE
  )
})

test_that("call_tool() gets the same result through the MCP Inspector", {
  skip_on_cran()
  skip_if_not_installed(
    "processx"
  )
  skip_if_not(
    nzchar(
      Sys.which(
        "npx"
      )
    ),
    "npx is not installed"
  )
  local_dev_package()

  expect_identical(
    call_tool(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog",
      client = "inspector"
    ),
    call_tool(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    )
  )
})
