local_totals_package <- function(
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
        "#' @mcpReturns json",
        "#' @mcpOutput type_object(runs = type_integer())",
        "totals <- function() {",
        "  list(runs = 12L)",
        "}",
        "",
        "#' Wrong totals",
        "#'",
        "#' Totals of the log, with a bug.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns json",
        "#' @mcpOutput type_object(runs = type_integer())",
        "wrong_totals <- function() {",
        "  list(runs = \"twelve\")",
        "}",
        "",
        "#' Echo",
        "#'",
        "#' Sends the text back.",
        "#'",
        "#' @param text Text to send back.",
        "#'",
        "#' @mcpTool",
        "#' @mcpType text type_string()",
        "#' @mcpReturns text",
        "echo <- function(text) {",
        "  text",
        "}"
      )
    ),
    env
  )
}

test_that("expect_structured_output() passes on a structured result that matches the output schema", {
  skip_if_not_installed(
    "processx"
  )
  local_totals_package()

  expect_success(
    expect_structured_output(
      "totals",
      package = "runlog"
    )
  )
})

test_that("expect_structured_output() fails on a tool without output schema", {
  skip_if_not_installed(
    "processx"
  )
  local_totals_package()

  expect_failure(
    expect_structured_output(
      "echo",
      list(
        text = "trail"
      ),
      package = "runlog"
    ),
    "Tool `echo` declares no @mcpOutput."
  )
})

test_that("expect_structured_output() fails on a result without structured content", {
  skip_if_not_installed(
    "processx"
  )
  local_totals_package()

  expect_failure(
    expect_structured_output(
      "wrong_totals",
      package = "runlog"
    ),
    "Tool `wrong_totals` returned no structured content:\nThe tool returned a result that does not match its output schema: Field `runs` must be of type integer."
  )
})

test_that("expect_structured_output() checks the structured content against the output schema itself", {
  local_totals_package()
  local_mocked_bindings(
    call_tool = function(
      ...
    ) {
      list(
        content = list(),
        structuredContent = list(
          runs = "twelve"
        ),
        isError = FALSE
      )
    }
  )

  expect_failure(
    expect_structured_output(
      "totals",
      package = "runlog"
    ),
    "Tool `totals` returned structured content that does not match its output schema: Field `runs` must be of type integer."
  )
})
