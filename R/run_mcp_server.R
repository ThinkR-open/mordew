#' Run an MCP server
#'
#' Serves the tools of an installed mordew package. It blocks the R process,
#' so it is meant to be the main loop of a dedicated process. Over stdio, it
#' serves the MCP client that started the R process: reads requests from
#' stdin and writes responses to stdout until the client closes stdin. Over
#' HTTP, it serves the Streamable HTTP transport of MCP on `host` and `port`:
#' the HTTP front answers `initialize`, `ping` and `tools/list` itself and
#' hands each tool call to a pool of mirai workers, so that it keeps serving
#' while tools run.
#'
#' @param package Name of the installed package whose tools to serve.
#' @param transport `"stdio"` or `"http"`.
#' @param host Address to listen on over HTTP: `"127.0.0.1"` serves this
#'   machine only, as the MCP specification recommends for a local server.
#' @param port Port to listen on over HTTP.
#' @param workers Number of R processes that run the tool calls over HTTP,
#'   each with the package loaded once.
#' @param timeout Seconds a tool call may run over HTTP before it is stopped
#'   and answered with an error. It counts from the start of the run, not
#'   the time spent in the queue.
#' @param queue Number of tool calls that may wait for a free worker over
#'   HTTP. A call that comes when the queue is full gets a "busy, retry
#'   later" error at once.
#' @param token Secret that every HTTP request but `GET /health` must send
#'   as `Authorization: Bearer <token>`, or get a 401. Taken from the
#'   `MORDEW_TOKEN` environment variable by default. Required to serve on
#'   another host than `127.0.0.1`, `localhost` or `::1`.
#'
#' @export
run_mcp_server <- function(
  package,
  transport = c(
    "stdio",
    "http"
  ),
  host = "127.0.0.1",
  port = 8000,
  workers = 4,
  timeout = 60,
  queue = 8,
  token = Sys.getenv(
    "MORDEW_TOKEN"
  )
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
    if (!nzchar(token)) {
      token <- NULL
    }
    if (
      is.null(
        token
      ) &&
        !host %in%
          c(
            "127.0.0.1",
            "localhost",
            "::1"
          )
    ) {
      stop(
        "Set a token to serve on ",
        host,
        ": without one, anyone who reaches the port can call the tools.",
        call. = FALSE
      )
    }
    return(
      serve_http(
        host,
        port,
        package,
        workers,
        timeout,
        queue,
        token
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
