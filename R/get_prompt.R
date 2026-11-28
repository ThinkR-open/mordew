#' Get a prompt through an MCP client
#'
#' Starts the package's MCP server in a separate R process and gets the
#' prompt over stdio, as an MCP client does: [call_tool()] for a prompt.
#'
#' @param prompt Name of the prompt.
#' @param args Named list of arguments, each a string.
#' @inheritParams call_tool
#'
#' @return The result of `prompts/get`: a list with `messages`.
#'
#' @export
get_prompt <- function(
  prompt,
  args = list(),
  package = testthat::testing_package(),
  timeout = 30
) {
  request_server(
    package,
    timeout,
    "prompts/get",
    named_call(
      prompt,
      args
    )
  )
}
