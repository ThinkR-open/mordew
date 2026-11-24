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
#' @param timeout Seconds to wait for each answer of the server.
#'
#' @return The tool result: a list with `content` and `isError`.
#'
#' @export
call_tool <- function(
  tool,
  args = list(),
  transport = "stdio",
  package = testthat::testing_package(),
  timeout = 30
) {
  match.arg(
    transport,
    "stdio"
  )
  client <- stdio_client(
    file.path(
      R.home(
        "bin"
      ),
      "Rscript"
    ),
    server_args(
      package
    ),
    timeout
  )
  on.exit(
    client_stop(
      client
    )
  )
  response <- client_request(
    client,
    "tools/call",
    list(
      name = tool,
      arguments = if (length(args) == 0) empty_object() else args
    )
  )
  if (!is.null(response$error)) {
    stop(
      response$error$message,
      call. = FALSE
    )
  }
  response$result$isError <- isTRUE(
    response$result$isError
  )
  response$result
}

server_args <- function(
  package
) {
  path <- find.package(
    package
  )
  c(
    "--no-init-file",
    "-e",
    paste0(
      ".libPaths(",
      paste(
        deparse(
          .libPaths()
        ),
        collapse = ""
      ),
      "); ",
      if (
        !dir.exists(
          file.path(
            path,
            "Meta"
          )
        )
      ) {
        paste0(
          "pkgload::load_all(",
          deparse(
            path
          ),
          ", quiet = TRUE); "
        )
      },
      package,
      "::run_mcp_server()"
    )
  )
}
