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
  error <- result$content[[1]]$text
  testthat::expect(
    result$isError &&
      (is.null(
        regexp
      ) ||
        grepl(
          regexp,
          error
        )),
    if (result$isError) {
      paste0(
        "The error of tool `",
        tool,
        "` does not match `",
        regexp,
        "`:\n",
        error
      )
    } else {
      paste0(
        "Tool `",
        tool,
        "` did not return an error."
      )
    }
  )
  invisible(
    result
  )
}
