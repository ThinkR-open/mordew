local_task_package <- function(
  env = parent.frame()
) {
  local_dev_package(
    local_tool_package(
      env,
      tools = c(
        "#' Totals",
        "#'",
        "#' Totals of the log.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "#' @mcpTask optional",
        "totals <- function() {",
        "  \"12 runs\"",
        "}",
        "",
        "#' Slow totals",
        "#'",
        "#' Totals of the log, that only run as a task.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "#' @mcpTask required",
        "slow_totals <- function() {",
        "  \"12 runs, slowly\"",
        "}"
      )
    ),
    env
  )
}

test_that("a tool runs as a task in a background process over stdio", {
  skip_if_not_installed(
    "processx"
  )
  local_task_package()
  client <- start_server(
    "runlog"
  )
  on.exit(
    client_stop(
      client
    )
  )

  task <- request_result(
    client,
    "tools/call",
    list(
      name = "totals",
      arguments = empty_object(),
      task = empty_object()
    )
  )$task
  result <- request_result(
    client,
    "tasks/result",
    list(
      taskId = task$taskId
    )
  )

  expect_identical(
    task$status,
    "working"
  )
  expect_identical(
    result$content[[1]]$text,
    "12 runs"
  )
  expect_identical(
    result$`_meta`[["io.modelcontextprotocol/related-task"]]$taskId,
    task$taskId
  )
})

test_that("call_tool() runs as a task a tool that requires one, or when asked", {
  skip_if_not_installed(
    "processx"
  )
  local_task_package()

  expect_identical(
    call_tool(
      "slow_totals",
      package = "runlog"
    )$content[[1]]$text,
    "12 runs, slowly"
  )
  expect_identical(
    call_tool(
      "totals",
      package = "runlog",
      task = TRUE
    )$content[[1]]$text,
    "12 runs"
  )
})
