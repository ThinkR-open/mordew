test_that("claude_tool_calls() returns the tool calls of the model", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir()
  )

  expect_identical(
    claude_tool_calls(
      "Show me my long runs in 2024.",
      local_runlog()
    ),
    list(
      tool_call(
        "fastest_runs",
        n = 3L,
        type = "interval"
      )
    )
  )
})

test_that("claude_tool_calls() asks the question in a session restricted to the server", {
  skip_on_os(
    "windows"
  )
  withr::local_envvar(
    ANTHROPIC_API_KEY = NA
  )
  record <- withr::local_tempdir()
  local_fake_claude(
    record
  )

  claude_tool_calls(
    "Show me my long runs in 2024.",
    local_runlog()
  )

  expect_identical(
    readLines(
      file.path(
        record,
        "args"
      )
    ),
    c(
      "-p",
      "Show me my long runs in 2024.",
      "--output-format",
      "stream-json",
      "--verbose",
      claude_args(
        "runlog"
      )
    )
  )
})

test_that("claude_tool_calls() serves the development version of the package", {
  skip_on_os(
    "windows"
  )
  record <- withr::local_tempdir()
  local_fake_claude(
    record
  )
  path <- local_runlog()

  claude_tool_calls(
    "Show me my long runs in 2024.",
    path
  )

  expect_identical(
    jsonlite::read_json(
      file.path(
        record,
        "config.json"
      )
    )$mcpServers$runlog,
    list(
      command = rscript(),
      args = as.list(
        server_args(
          "runlog",
          normalizePath(
            path
          )
        )
      )
    )
  )
})

test_that("claude_tool_calls() stops with the message of a failed session", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir(),
    stream = "claude-not-logged-in.jsonl",
    status = 1
  )

  expect_error(
    claude_tool_calls(
      "Show me my long runs in 2024.",
      local_runlog()
    ),
    "Not logged in · Please run /login",
    fixed = TRUE
  )
})

test_that("claude_tool_calls() stops with the errors of the CLI", {
  skip_on_os(
    "windows"
  )
  local_fake_claude(
    withr::local_tempdir(),
    stream = NULL,
    stderr = "error: unknown option '--not-a-flag'",
    status = 1
  )

  expect_error(
    claude_tool_calls(
      "Show me my long runs in 2024.",
      local_runlog()
    ),
    "error: unknown option '--not-a-flag'",
    fixed = TRUE
  )
})

test_that("claude_tool_calls() leaves the developer's configuration out when an API key is set", {
  skip_on_os(
    "windows"
  )
  withr::local_envvar(
    ANTHROPIC_API_KEY = "test-key"
  )
  record <- withr::local_tempdir()
  local_fake_claude(
    record
  )

  claude_tool_calls(
    "Show me my long runs in 2024.",
    local_runlog()
  )

  expect_contains(
    readLines(
      file.path(
        record,
        "args"
      )
    ),
    "--bare"
  )
})
