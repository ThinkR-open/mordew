#' Run an MCP server
#'
#' Serves the tools, resources and prompts of an installed mordew package.
#' It blocks the R process, so it is meant to be the main loop of a
#' dedicated process. Over stdio, it serves the MCP client that started the
#' R process: reads requests from stdin and writes responses to stdout until
#' the client closes stdin. Over HTTP, it serves the Streamable HTTP transport of MCP on `host`
#' and `port`: the HTTP front answers `initialize`, `ping` and the lists
#' itself and hands each tool call, resource read and prompt get to a pool
#' of mirai workers, so that it keeps serving while tools run.
#'
#' @param package Name of the installed package whose tools, resources and
#'   prompts to serve.
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
#' @param completions Completion requests answered per second, over stdio
#'   and HTTP, as the MCP specification asks servers to limit them; the
#'   others get an error asking to retry later. `Inf` answers them all.
#' @param tool_calls Tool calls run per second, over stdio and HTTP, as the
#'   MCP specification asks servers to limit them; the others get an error
#'   result asking to retry later. `Inf` runs them all.
#' @param token Secret that every HTTP request but `GET /health` must send
#'   as `Authorization: Bearer <token>`, or get a 401. Taken from the
#'   `MORDEW_TOKEN` environment variable by default; `NULL` or `""` serves
#'   without a token. Serving on another host
#'   than `127.0.0.1`, `localhost` or `::1` without one prints a warning.
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
  ),
  completions = 10,
  tool_calls = 10
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
    if (identical(token, "")) {
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
      message(
        "Serving on ",
        host,
        " without a token: anyone who reaches the port can call the tools.",
        " Set MORDEW_TOKEN, or put an authenticating proxy in front."
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
        token,
        completions,
        tool_calls
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
    namespace,
    namespace$mordew_resources,
    namespace$mordew_prompts,
    rate_limits(
      completions,
      tool_calls
    )
  )
}
