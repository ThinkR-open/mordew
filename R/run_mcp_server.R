#' Run an MCP server
#'
#' Serves the tools of an installed mordew package. It blocks the R process,
#' so it is meant to be the main loop of a dedicated process. Over stdio, it
#' serves the MCP client that started the R process: reads requests from
#' stdin and writes responses to stdout until the client closes stdin. Over
#' HTTP, it serves the Streamable HTTP transport of MCP on `host` and `port`,
#' one call at a time.
#'
#' @param package Name of the installed package whose tools to serve.
#' @param transport `"stdio"` or `"http"`.
#' @param host Address to listen on over HTTP: `"127.0.0.1"` serves this
#'   machine only, as the MCP specification recommends for a local server.
#' @param port Port to listen on over HTTP.
#'
#' @export
run_mcp_server <- function(
  package,
  transport = c(
    "stdio",
    "http"
  ),
  host = "127.0.0.1",
  port = 8000
) {
  namespace <- asNamespace(
    package
  )
  if (
    match.arg(
      transport
    ) ==
      "http"
  ) {
    return(
      serve_http(
        host,
        port,
        server_identity(
          package
        ),
        namespace$mordew_registry,
        namespace
      )
    )
  }
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
