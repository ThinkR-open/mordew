handle_message <- function(
  message,
  server,
  registry,
  envir,
  resources,
  prompts
) {
  if (!is.list(message) || is.null(names(message))) {
    return(
      invalid_request(
        NULL
      )
    )
  }
  if (is.null(message[["id"]])) {
    return(
      NULL
    )
  }
  if (!is.character(message[["method"]])) {
    return(
      invalid_request(
        message[["id"]]
      )
    )
  }
  rpc_response(
    message[["id"]],
    switch(
      message[["method"]],
      initialize = list(
        result = list(
          protocolVersion = "2025-11-25",
          capabilities = list(
            tools = empty_object(),
            resources = empty_object(),
            prompts = empty_object(),
            completions = empty_object()
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
          tools = definitions(
            registry,
            "tool"
          )
        )
      ),
      "resources/list" = list(
        result = list(
          resources = definitions(
            Filter(
              Negate(
                is_template
              ),
              resources
            ),
            "resource"
          )
        )
      ),
      "resources/templates/list" = list(
        result = list(
          resourceTemplates = definitions(
            Filter(
              is_template,
              resources
            ),
            "resource"
          )
        )
      ),
      "resources/read" = resources_read(
        message[["params"]],
        resources,
        envir
      ),
      "prompts/list" = list(
        result = list(
          prompts = definitions(
            prompts,
            "prompt"
          )
        )
      ),
      "prompts/get" = prompts_get(
        message[["params"]],
        prompts,
        envir
      ),
      "completion/complete" = completion_complete(
        message[["params"]],
        resources,
        prompts,
        envir
      ),
      "tools/call" = tools_call(
        message[["params"]],
        registry,
        envir
      ),
      rpc_error(
        -32601,
        paste0(
          "Method not found: ",
          message[["method"]]
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
  if (
    !is.list(params) ||
      !is.character(params[["name"]]) ||
      (length(params[["arguments"]]) > 0 &&
        is.null(names(params[["arguments"]])))
  ) {
    return(
      rpc_error(
        -32602,
        "Invalid params"
      )
    )
  }
  entry <- registry[[params[["name"]]]]
  if (is.null(entry)) {
    return(
      rpc_error(
        -32602,
        paste0(
          "Unknown tool: ",
          params[["name"]]
        )
      )
    )
  }
  arguments <- as.list(
    params[["arguments"]]
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

resources_read <- function(
  params,
  resources,
  envir
) {
  if (
    !is.list(params) ||
      !is.character(params[["uri"]])
  ) {
    return(
      rpc_error(
        -32602,
        "Invalid params"
      )
    )
  }
  found <- find_resource(
    params[["uri"]],
    resources
  )
  if (is.null(found)) {
    return(
      rpc_error(
        -32002,
        paste0(
          "Resource not found: ",
          params[["uri"]]
        )
      )
    )
  }
  resource_result(
    params[["uri"]],
    found$entry,
    found$args,
    envir
  )
}

find_resource <- function(
  uri,
  resources
) {
  entry <- resources[[uri]]
  if (!is.null(entry$resource$uri)) {
    return(
      list(
        entry = entry,
        args = list()
      )
    )
  }
  for (entry in Filter(is_template, resources)) {
    args <- template_arguments(
      uri,
      entry$resource$uriTemplate
    )
    if (!is.null(args)) {
      return(
        list(
          entry = entry,
          args = args
        )
      )
    }
  }
  NULL
}

template_arguments <- function(
  uri,
  template
) {
  literals <- regmatches(
    template,
    gregexpr(
      "\\{[^{}]*\\}",
      template
    ),
    invert = TRUE
  )[[1]]
  values <- regmatches(
    uri,
    regexec(
      paste0(
        "^",
        paste0(
          "\\Q",
          literals,
          "\\E",
          collapse = "([^/]+)"
        ),
        "$"
      ),
      uri,
      perl = TRUE
    )
  )[[1]]
  if (length(values) == 0) {
    return(
      NULL
    )
  }
  stats::setNames(
    as.list(
      values[-1]
    ),
    uri_variables(
      template
    )
  )
}

resource_result <- function(
  uri,
  entry,
  args,
  envir
) {
  tryCatch(
    {
      value <- do.call(
        entry$fun,
        args,
        envir = envir
      )
      if (
        !has_kind(
          value,
          entry$returns
        )
      ) {
        stop(
          "The resource returns ",
          entry$returns,
          ", but returned class ",
          class(value)[[1]],
          "."
        )
      }
      content <- kind_content(
        value,
        entry$returns
      )[[1]]
      list(
        result = list(
          contents = list(
            c(
              list(
                uri = uri,
                mimeType = entry$resource$mimeType
              ),
              if (entry$returns == "image") {
                list(
                  blob = content$data
                )
              } else {
                content["text"]
              }
            )
          )
        )
      )
    },
    error = function(
      error
    ) {
      rpc_error(
        -32603,
        conditionMessage(
          error
        )
      )
    }
  )
}

prompts_get <- function(
  params,
  prompts,
  envir
) {
  if (
    !is.list(params) ||
      !is.character(params[["name"]]) ||
      (length(params[["arguments"]]) > 0 &&
        is.null(names(params[["arguments"]])))
  ) {
    return(
      rpc_error(
        -32602,
        "Invalid params"
      )
    )
  }
  entry <- prompts[[params[["name"]]]]
  if (is.null(entry)) {
    return(
      rpc_error(
        -32602,
        paste0(
          "Unknown prompt: ",
          params[["name"]]
        )
      )
    )
  }
  arguments <- as.list(
    params[["arguments"]]
  )
  invalid <- tryCatch(
    validate_arguments(
      arguments,
      prompt_schema(
        entry$prompt$arguments
      )
    ),
    error = conditionMessage
  )
  if (is.character(invalid)) {
    return(
      rpc_error(
        -32602,
        invalid
      )
    )
  }
  prompt_result(
    entry,
    arguments,
    envir
  )
}

prompt_schema <- function(
  arguments
) {
  names <- vapply(
    arguments,
    `[[`,
    "",
    "name"
  )
  list(
    properties = stats::setNames(
      lapply(
        names,
        function(name) {
          list(
            type = "string"
          )
        }
      ),
      names
    ),
    required = names[vapply(
      arguments,
      `[[`,
      TRUE,
      "required"
    )]
  )
}

prompt_result <- function(
  entry,
  arguments,
  envir
) {
  tryCatch(
    {
      value <- do.call(
        entry$fun,
        arguments,
        envir = envir
      )
      if (
        !has_kind(
          value,
          "text"
        )
      ) {
        stop(
          "The prompt returns text, but returned class ",
          class(value)[[1]],
          "."
        )
      }
      list(
        result = list(
          messages = list(
            list(
              role = "user",
              content = kind_content(
                value,
                "text"
              )[[1]]
            )
          )
        )
      )
    },
    error = function(
      error
    ) {
      rpc_error(
        -32603,
        conditionMessage(
          error
        )
      )
    }
  )
}

completion_complete <- function(
  params,
  resources,
  prompts,
  envir
) {
  argument <- params[["argument"]]
  if (
    !is.list(params) ||
      !is.list(argument) ||
      !is.character(argument[["name"]]) ||
      !is.character(argument[["value"]])
  ) {
    return(
      rpc_error(
        -32602,
        "Invalid params"
      )
    )
  }
  entry <- completion_entry(
    params[["ref"]],
    resources,
    prompts
  )
  if (is.null(entry)) {
    return(
      rpc_error(
        -32602,
        "Unknown prompt or resource template."
      )
    )
  }
  completion_result(
    entry$complete[[argument[["name"]]]],
    argument[["value"]],
    envir
  )
}

completion_entry <- function(
  ref,
  resources,
  prompts
) {
  if (identical(ref[["type"]], "ref/prompt")) {
    return(
      entry_of(
        prompts,
        ref[["name"]]
      )
    )
  }
  if (identical(ref[["type"]], "ref/resource")) {
    entry_of(
      Filter(
        is_template,
        resources
      ),
      ref[["uri"]]
    )
  }
}

entry_of <- function(
  entries,
  key
) {
  if (is.character(key) && length(key) == 1) {
    entries[[key]]
  }
}

completion_result <- function(
  fun,
  value,
  envir
) {
  tryCatch(
    {
      values <- if (is.null(fun)) {
        character()
      } else {
        do.call(
          fun,
          list(
            value
          ),
          envir = envir
        )
      }
      if (
        !has_kind(
          values,
          "text"
        )
      ) {
        stop(
          "The completion returns text, but returned class ",
          class(values)[[1]],
          "."
        )
      }
      list(
        result = list(
          completion = list(
            values = as.list(
              utils::head(
                values,
                100
              )
            ),
            total = length(
              values
            ),
            hasMore = length(values) > 100
          )
        )
      )
    },
    error = function(
      error
    ) {
      rpc_error(
        -32603,
        conditionMessage(
          error
        )
      )
    }
  )
}

is_template <- function(
  entry
) {
  !is.null(
    entry$resource$uriTemplate
  )
}

definitions <- function(
  entries,
  field
) {
  unname(
    lapply(
      entries,
      `[[`,
      field
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
