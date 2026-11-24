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
      handle_message(
        message,
        server,
        registry,
        envir
      )
    }
    if (is.null(response)) {
      next
    }
    writeLines(
      jsonlite::toJSON(
        response,
        auto_unbox = TRUE,
        digits = NA,
        null = "null"
      ),
      output,
      useBytes = TRUE
    )
    flush(
      output
    )
  }
}
