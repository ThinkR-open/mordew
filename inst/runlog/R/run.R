#' Run the MCP server
#'
#' Serves the package's tools to MCP clients: over stdio by default, to the
#' client that started the R process, until it closes stdin; over HTTP with
#' `transport = "http"`.
#'
#' @param ... Passed to [mordew::run_mcp_server()]: `transport`, `host`,
#'   `port` and `workers`.
#'
#' @export
run_mcp_server <- function(
  ...
) {
  mordew::run_mcp_server(
    "runlog",
    ...
  )
}
