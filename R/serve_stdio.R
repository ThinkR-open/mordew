serve_stdio <- function(
  input,
  output,
  server,
  registry,
  envir
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
    message <- tryCatch(
      jsonlite::fromJSON(
        line,
        simplifyVector = FALSE
      ),
      error = identity
    )
    response <- if (
      inherits(
        message,
        "error"
      )
    ) {
      rpc_response(
        NULL,
        rpc_error(
          -32700,
          "Parse error"
        )
      )
    } else {
      stdout_to_stderr(
        handle_message(
          message,
          server,
          registry,
          envir
        )
      )
    }
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
