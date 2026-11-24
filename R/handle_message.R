handle_message <- function(
  message,
  server,
  registry,
  envir
) {
  if (!is.list(message) || is.null(names(message))) {
    return(
      invalid_request(
        NULL
      )
    )
  }
  if (is.null(message$id)) {
    return(
      NULL
    )
  }
  if (!is.character(message$method)) {
    return(
      invalid_request(
        message$id
      )
    )
  }
  rpc_response(
    message$id,
    switch(
      message$method,
      initialize = list(
        result = list(
          protocolVersion = "2025-11-25",
          capabilities = list(
            tools = empty_object()
          ),
          serverInfo = server[c(
            "name",
            "version"
          )],
          instructions = server$instructions
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
  if (!is.character(params$name)) {
    return(
      rpc_error(
        -32602,
        "Invalid params"
      )
    )
  }
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
  arguments <- as.list(
    params$arguments
  )
  list(
    result = tryCatch(
      {
        validate_arguments(
          arguments,
          entry$tool$inputSchema
        )
        tool_result(
          do.call(
            entry$fun,
            as_r_value(
              arguments,
              entry$tool$inputSchema
            ),
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

rpc_response <- function(
  id,
  body
) {
  c(
    list(
      jsonrpc = "2.0",
      id = id
    ),
    body
  )
}

invalid_request <- function(
  id
) {
  rpc_response(
    id,
    rpc_error(
      -32600,
      "Invalid Request"
    )
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
