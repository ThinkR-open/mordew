#' Read a resource through an MCP client
#'
#' Starts the package's MCP server in a separate R process and reads the
#' resource over stdio, as an MCP client does: [call_tool()] for a resource.
#'
#' @param uri URI of the resource.
#' @inheritParams call_tool
#'
#' @return The result of `resources/read`: a list with `contents`.
#'
#' @export
read_resource <- function(
  uri,
  package = testthat::testing_package(),
  timeout = 30
) {
  request_server(
    package,
    timeout,
    "resources/read",
    list(
      uri = uri
    )
  )
}
