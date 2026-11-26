test_that("expect_hostile_safe() passes on a tool that answers extreme values", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_success(
    expect_hostile_safe(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    )
  )
})

test_that("expect_hostile_safe() refuses an unknown tool", {
  local_dev_package()

  expect_error(
    expect_hostile_safe(
      "nope",
      package = "runlog"
    ),
    "`runlog` has no tool named `nope`."
  )
})

test_that("expect_hostile_safe() fails on a tool that hangs on an extreme value", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package(
    local_tool_package(
      tools = c(
        "#' Wait",
        "#'",
        "#' Waits for some seconds.",
        "#'",
        "#' @param seconds Seconds to wait.",
        "#'",
        "#' @mcpTool",
        "#' @mcpType seconds type_number(min = 0)",
        "#' @mcpReturns text",
        "nap <- function(seconds) {",
        "  Sys.sleep(min(seconds, 60))",
        "  \"Done.\"",
        "}"
      )
    )
  )

  expect_failure(
    expect_hostile_safe(
      "nap",
      list(
        seconds = 0
      ),
      package = "runlog",
      timeout = 1
    ),
    "Tool `nap` failed with `seconds` = 1.797693e+308:\nThe server did not answer `tools/call` within 1 seconds.",
    fixed = TRUE
  )
})

test_that("expect_hostile_safe() fails on a tool that stops the server", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package(
    local_tool_package(
      tools = c(
        "#' Echo the text",
        "#'",
        "#' Sends the text back.",
        "#'",
        "#' @param text Text to send back.",
        "#'",
        "#' @mcpTool",
        "#' @mcpType text type_string()",
        "#' @mcpReturns text",
        "echo <- function(text) {",
        "  if (nchar(text) > 1000) quit(save = \"no\", status = 1)",
        "  text",
        "}"
      )
    )
  )

  expect_failure(
    expect_hostile_safe(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    ),
    "Tool `echo` failed with `text` = a string of 100000 characters:\nThe server stopped (exit status 1).",
    fixed = TRUE
  )
})

test_that("expect_hostile_safe() fails on arguments the schema rejects", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_failure(
    expect_hostile_safe(
      "echo",
      package = "runlog"
    ),
    "The arguments of `echo` are not valid: Missing argument `text`.",
    fixed = TRUE
  )
})
