#' Call a tool through an MCP client
#'
#' Starts the package's MCP server in a separate R process and calls the tool
#' over stdio, as an MCP client does. A package loaded from source, as under
#' `devtools::test()`, is served in its development version through
#' `pkgload::load_all()`; an installed package, as under `R CMD check`, in its
#' installed version.
#'
#' @param tool Name of the tool.
#' @param args Named list of arguments.
#' @param transport Transport to the server: `"stdio"`.
#' @param package Package that serves the tool, by default the one being
#'   tested.
#' @param timeout Seconds to wait for each answer of the server, with the
#'   `"mordew"` client.
#' @param client MCP client that calls the tool: `"mordew"`, its own, or
#'   `"inspector"`, the MCP Inspector run through `npx`, which needs Node.js. A
#'   client written by others checks that the server is understood beyond
#'   `{mordew}`'s own reading of the protocol. `"inspector"` is not supported
#'   on Windows yet.
#' @param task `TRUE` runs the tool as a task, through `tasks/result`, with
#'   the `"mordew"` client. A tool tagged `@mcpTask required` always runs as
#'   one.
#'
#' @return The tool result: a list with `content` and `isError`.
#'
#' @export
call_tool <- function(
  tool,
  args = list(),
  transport = "stdio",
  package = testthat::testing_package(),
  timeout = 30,
  client = c(
    "mordew",
    "inspector"
  ),
  task = FALSE
) {
  match.arg(
    transport,
    "stdio"
  )
  result <- switch(
    match.arg(
      client
    ),
    mordew = mordew_call(
      tool,
      args,
      package,
      timeout,
      task
    ),
    inspector = inspector_call(
      tool,
      args,
      package
    )
  )
  result$isError <- isTRUE(
    result$isError
  )
  result
}

mordew_call <- function(
  tool,
  args,
  package,
  timeout,
  task
) {
  client <- start_server(
    package,
    timeout = timeout
  )
  on.exit(
    client_stop(
      client
    )
  )
  request_tool(
    client,
    tool,
    args,
    task
  )
}

inspector_call <- function(
  tool,
  args,
  package
) {
  if (on_windows()) {
    stop(
      "The MCP Inspector client is not supported on Windows yet.",
      call. = FALSE
    )
  }
  run <- processx::run(
    "npx",
    c(
      "-y",
      "@modelcontextprotocol/inspector@2.16.0",
      "--cli",
      "--method",
      "tools/call",
      "--tool-name",
      tool,
      "--tool-args-json",
      json_line(
        if (length(args) == 0) empty_object() else args
      ),
      "--",
      rscript(),
      server_args(
        package,
        find.package(
          package
        )
      )
    ),
    error_on_status = FALSE,
    env = c(
      "current",
      NODE_DISABLE_COMPILE_CACHE = "1"
    )
  )
  if (run$status != 0) {
    stop(
      "The MCP Inspector failed: ",
      utils::tail(
        strsplit(
          run$stderr,
          "\n"
        )[[1]],
        1
      ),
      call. = FALSE
    )
  }
  jsonlite::fromJSON(
    run$stdout,
    simplifyVector = FALSE
  )
}
