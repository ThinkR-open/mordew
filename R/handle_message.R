handle_message <- function(
  message,
  identity,
  registry,
  envir
) {
  if (is.null(message$id)) {
    return(
      NULL
    )
  }
  c(
    list(
      jsonrpc = "2.0",
      id = message$id
    ),
    switch(
      message$method,
      initialize = list(
        result = list(
          protocolVersion = "2025-11-25",
          capabilities = list(
            tools = empty_object()
          ),
          serverInfo = identity[c(
            "name",
            "version"
          )],
          instructions = identity$instructions
        )
      ),
      ping = list(
        result = empty_object()
      ),
      "tools/list" = list(
        result = list(
          tools = unname(
            lapply(
              registry,
              `[[`,
              "tool"
            )
          )
        )
      ),
      "tools/call" = tools_call(
        message$params,
        registry,
        envir
      ),
      rpc_error(
        -32601,
        paste0(
          "Method not found: ",
          message$method
        )
      )
    )
  )
}

tools_call <- function(
  params,
  registry,
  envir
) {
  entry <- registry[[params$name]]
  if (is.null(entry)) {
    return(
      rpc_error(
        -32602,
        paste0(
          "Unknown tool: ",
          params$name
        )
      )
    )
  }
  list(
    result = tryCatch(
      {
        validate_arguments(
          params$arguments,
          entry$tool$inputSchema
        )
        tool_result(
          do.call(
            entry$fun,
            params$arguments,
            envir = envir
          ),
          entry$returns,
          entry$limit$rows
        )
      },
      error = function(
        error
      ) {
        tool_result(
          error,
          entry$returns
        )
      }
    )
  )
}

empty_object <- function() {
  structure(
    list(),
    names = character()
  )
}

rpc_error <- function(
  code,
  message
) {
  list(
    error = list(
      code = code,
      message = message
    )
  )
}
