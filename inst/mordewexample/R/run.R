#' Run the MCP server
#'
#' Serves the package's tools over stdio to the MCP client that started the
#' R process, until the client closes stdin.
#'
#' @export
run_mcp_server <- function() {
  mordew::run_mcp_server(
    "mordewexample"
  )
}
