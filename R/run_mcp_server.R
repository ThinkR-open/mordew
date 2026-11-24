#' Run an MCP server over stdio
#'
#' Serves the tools of an installed mordew package to the MCP client that
#' started the R process: reads requests from stdin and writes responses to
#' stdout until the client closes stdin. It blocks the R process, so it is
#' meant to be the main loop of a dedicated process.
#'
#' @param package Name of the installed package whose tools to serve.
#'
#' @export
run_mcp_server <- function(
  package
) {
  namespace <- asNamespace(
    package
  )
  input <- file(
    "stdin",
    open = "r"
  )
  on.exit(
    close(
      input
    )
  )
  serve_stdio(
    input,
    stdout(),
    server_identity(
      package
    ),
    namespace$mordew_registry,
    namespace
  )
}
