#' Expect a tool to return an error result
#'
#' Calls the tool with [call_tool()] and expects an `isError` result: the error
#' the model reads, not a crash of the server.
#'
#' @inheritParams call_tool
#' @param regexp Regular expression the error message must match, or `NULL`.
#' @param ... Passed to [call_tool()].
#'
#' @return The tool result, invisibly.
#'
#' @export
expect_tool_error <- function(
  tool,
  args = list(),
  regexp = NULL,
  ...
) {
  result <- call_tool(
    tool,
    args,
    ...
  )
  testthat::expect(
    result$isError,
    paste0(
      "Tool `",
      tool,
      "` did not return an error."
    )
  )
  if (!is.null(regexp)) {
    testthat::expect_match(
      result$content[[1]]$text,
      regexp
    )
  }
  invisible(
    result
  )
}
