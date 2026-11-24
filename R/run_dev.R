#' Try the tools with a model
#'
#' Starts the development version of the package's MCP server, connects an
#' ellmer chat to it through MCP, and opens the chat. The model sees the tools
#' exactly as any MCP client sends them, and each tool call is shown with its
#' arguments. Changing a tool means restarting `run_dev()`.
#'
#' @param client Client to chat through: `"ellmer"`.
#' @param chat An ellmer chat, such as `ellmer::chat_anthropic()`. The
#'   server's instructions are added to its system prompt.
#' @param ui `"console"` for `ellmer::live_console()`, `"browser"` for
#'   `ellmer::live_browser()`.
#' @param pkg Path to the package.
#' @param timeout Seconds to wait for each answer of the server.
#'
#' @return The chat, invisibly.
#'
#' @export
run_dev <- function(
  client = "ellmer",
  chat,
  ui = c(
    "console",
    "browser"
  ),
  pkg = ".",
  timeout = 30
) {
  match.arg(
    client,
    "ellmer"
  )
  ui <- match.arg(
    ui
  )
  connection <- start_server(
    read.dcf(
      file.path(
        pkg,
        "DESCRIPTION"
      ),
      "Package"
    )[[1]],
    normalizePath(
      pkg
    ),
    timeout
  )
  on.exit(
    client_stop(
      connection
    )
  )
  chat$set_system_prompt(
    c(
      chat$get_system_prompt(),
      connection$server$instructions
    )
  )
  chat$set_tools(
    ellmer_tools(
      connection
    )
  )
  switch(
    ui,
    console = ellmer::live_console(
      chat
    ),
    browser = ellmer::live_browser(
      chat
    )
  )
  invisible(
    chat
  )
}

ellmer_tools <- function(
  client
) {
  lapply(
    client_request(
      client,
      "tools/list"
    )$result$tools,
    ellmer_tool,
    client
  )
}

ellmer_tool <- function(
  tool,
  client
) {
  properties <- tool$inputSchema$properties
  arguments <- lapply(
    names(
      properties
    ),
    function(
      name
    ) {
      type <- ellmer::type_from_schema(
        text = json_line(
          properties[[name]]
        )
      )
      type@required <- name %in% tool$inputSchema$required
      type
    }
  )
  names(arguments) <- names(
    properties
  )
  call <- function() {
    result <- request_tool(
      client,
      tool$name,
      Filter(
        Negate(
          is.null
        ),
        as.list(
          environment()
        )
      )
    )
    if (isTRUE(result$isError)) {
      stop(
        tool_text(
          result
        ),
        call. = FALSE
      )
    }
    tool_text(
      result
    )
  }
  formals(call) <- lapply(
    arguments,
    function(
      type
    ) {
      NULL
    }
  )
  ellmer::tool(
    call,
    tool$description,
    arguments = arguments,
    name = tool$name,
    convert = FALSE
  )
}

tool_text <- function(
  result
) {
  paste(
    vapply(
      result$content,
      function(
        item
      ) {
        if (item$type == "text") {
          return(
            item$text
          )
        }
        paste0(
          "[The tool returned an ",
          item$mimeType,
          " image, which ellmer sends to the model as text only.]"
        )
      },
      character(1)
    ),
    collapse = "\n"
  )
}
