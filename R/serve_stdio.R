serve_stdio <- function(
  input,
  output,
  server,
  registry,
  envir,
  resources,
  prompts,
  limit = NULL
) {
  repeat {
    line <- readLines(
      input,
      n = 1,
      encoding = "UTF-8"
    )
    if (length(line) == 0) {
      break
    }
    response <- respond(
      line,
      server,
      registry,
      envir,
      resources,
      prompts,
      limit
    )
    if (is.null(response)) {
      next
    }
    writeLines(
      json_line(
        response
      ),
      output,
      useBytes = TRUE
    )
    flush(
      output
    )
  }
}

respond <- function(
  text,
  server,
  registry,
  envir,
  resources,
  prompts,
  limit = NULL
) {
  message <- tryCatch(
    jsonlite::fromJSON(
      text,
      simplifyVector = FALSE
    ),
    error = identity
  )
  if (
    inherits(
      message,
      "error"
    )
  ) {
    return(
      rpc_response(
        NULL,
        rpc_error(
          -32700,
          "Parse error"
        )
      )
    )
  }
  limited <- limited_response(
    message,
    limit
  )
  if (!is.null(limited)) {
    return(
      limited
    )
  }
  stdout_to_stderr(
    handle_message(
      message,
      server,
      registry,
      envir,
      resources,
      prompts
    )
  )
}

stdout_to_stderr <- function(
  code
) {
  sink(
    stderr()
  )
  on.exit(
    sink()
  )
  code
}

json_line <- function(
  message
) {
  jsonlite::toJSON(
    message,
    auto_unbox = TRUE,
    digits = NA,
    null = "null"
  )
}
