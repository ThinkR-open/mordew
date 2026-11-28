#' Expect a tool to return structured content that matches its output schema
#'
#' Calls the tool with [call_tool()] and checks its `structuredContent`
#' against the output schema that `@mcpOutput` declares, as the MCP
#' specification asks clients to do.
#'
#' @inheritParams call_tool
#' @param ... Passed to [call_tool()].
#'
#' @return The tool result, invisibly.
#'
#' @export
expect_structured_output <- function(
  tool,
  args = list(),
  package = testthat::testing_package(),
  ...
) {
  schema <- tool_definition(
    tool,
    package
  )$outputSchema
  result <- call_tool(
    tool,
    args,
    package = package,
    ...
  )
  problem <- structured_problem(
    result,
    schema
  )
  testthat::expect(
    is.null(
      problem
    ),
    paste0(
      "Tool `",
      tool,
      "` ",
      problem
    )
  )
  invisible(
    result
  )
}

structured_problem <- function(
  result,
  schema
) {
  if (is.null(schema)) {
    return(
      "declares no @mcpOutput."
    )
  }
  if (is.null(result$structuredContent)) {
    return(
      paste0(
        "returned no structured content:\n",
        result$content[[1]]$text
      )
    )
  }
  tryCatch(
    validate_arguments(
      result$structuredContent,
      schema,
      "field"
    ),
    error = function(
      error
    ) {
      paste0(
        "returned structured content that does not match its output schema: ",
        conditionMessage(
          error
        )
      )
    }
  )
}
