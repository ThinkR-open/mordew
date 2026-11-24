stdio_client <- function(
  command,
  args = character(),
  timeout = 30
) {
  client <- new.env(
    parent = emptyenv()
  )
  client$timeout <- timeout
  client$last_id <- 0L
  client$buffer <- ""
  client$errors <- tempfile()
  client$process <- processx::process$new(
    command,
    args,
    stdin = "|",
    stdout = "|",
    stderr = client$errors,
    encoding = "UTF-8"
  )
  response <- client_request(
    client,
    "initialize",
    list(
      protocolVersion = "2025-11-25",
      capabilities = empty_object(),
      clientInfo = list(
        name = "mordew",
        version = as.character(
          utils::packageVersion(
            "mordew"
          )
        )
      )
    )
  )
  if (
    !identical(
      response$result$protocolVersion,
      "2025-11-25"
    )
  ) {
    client_stop(
      client
    )
    stop(
      "The server does not speak MCP 2025-11-25: ",
      json_line(
        response
      )
    )
  }
  client_send(
    client,
    list(
      jsonrpc = "2.0",
      method = "notifications/initialized"
    )
  )
  client
}

client_request <- function(
  client,
  method,
  params = NULL
) {
  client$last_id <- client$last_id + 1L
  request <- list(
    jsonrpc = "2.0",
    id = client$last_id,
    method = method
  )
  request$params <- params
  client_send(
    client,
    request
  )
  client_receive(
    client,
    method
  )
}

client_send <- function(
  client,
  message
) {
  left <- charToRaw(
    enc2utf8(
      paste0(
        json_line(
          message
        ),
        "\n"
      )
    )
  )
  deadline <- Sys.time() + client$timeout
  repeat {
    left <- tryCatch(
      client$process$write_input(
        left
      ),
      error = function(
        error
      ) {
        stop_server_stopped(
          client
        )
      }
    )
    if (length(left) == 0) {
      return(
        invisible()
      )
    }
    if (Sys.time() > deadline) {
      stop_timeout(
        client,
        message$method
      )
    }
    Sys.sleep(
      0.01
    )
  }
}

client_receive <- function(
  client,
  method
) {
  deadline <- Sys.time() + client$timeout
  repeat {
    for (line in take_lines(client)) {
      response <- tryCatch(
        jsonlite::fromJSON(
          line,
          simplifyVector = FALSE
        ),
        error = function(
          error
        ) {
          NULL
        }
      )
      if (
        is.list(
          response
        ) &&
          identical(
            response$id,
            client$last_id
          )
      ) {
        return(
          response
        )
      }
    }
    remaining <- as.numeric(
      difftime(
        deadline,
        Sys.time(),
        units = "secs"
      )
    )
    if (remaining <= 0) {
      stop_timeout(
        client,
        method
      )
    }
    client$process$poll_io(
      ceiling(
        remaining * 1000
      )
    )
    chunk <- client$process$read_output()
    if (!nzchar(chunk) && !client$process$is_incomplete_output()) {
      stop_server_stopped(
        client
      )
    }
    client$buffer <- paste0(
      client$buffer,
      chunk
    )
  }
}

take_lines <- function(
  client
) {
  newline <- regexpr(
    "\n[^\n]*$",
    client$buffer
  )
  if (newline < 0) {
    return(
      character()
    )
  }
  lines <- strsplit(
    substr(
      client$buffer,
      1,
      newline - 1
    ),
    "\n",
    fixed = TRUE
  )[[1]]
  client$buffer <- substring(
    client$buffer,
    newline + 1
  )
  lines
}

stop_timeout <- function(
  client,
  method
) {
  stop(
    "The server did not answer `",
    method,
    "` within ",
    client$timeout,
    " seconds.",
    call. = FALSE
  )
}

stop_server_stopped <- function(
  client
) {
  stop(
    paste(
      c(
        "The server stopped.",
        utils::tail(
          readLines(
            client$errors,
            warn = FALSE
          ),
          20
        )
      ),
      collapse = "\n"
    ),
    call. = FALSE
  )
}

client_stop <- function(
  client
) {
  close(
    client$process$get_input_connection()
  )
  client$process$wait(
    client$timeout * 1000
  )
  client$process$kill()
  invisible()
}
