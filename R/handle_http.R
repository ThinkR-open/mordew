handle_http <- function(
  request,
  server,
  registry,
  envir,
  pool = NULL,
  token = NULL
) {
  reply <- reply_from_headers(
    request,
    token
  )
  if (!is.null(reply)) {
    return(
      reply
    )
  }
  message <- if (
    !is.null(
      pool
    )
  ) {
    tool_call_message(
      request$body
    )
  }
  if (!is.null(message)) {
    return(
      pool_call(
        pool,
        message,
        request$body,
        server
      )
    )
  }
  http_reply(
    respond(
      request$body,
      server,
      registry,
      envir
    )
  )
}

reply_from_headers <- function(
  request,
  token
) {
  if (
    !local_origin(
      request$headers$origin
    )
  ) {
    return(
      http_response(
        403L
      )
    )
  }
  if (
    identical(
      request$path,
      "/health"
    )
  ) {
    return(
      http_response(
        200L,
        list(
          "Content-Type" = "application/json"
        ),
        '{"status":"ok"}'
      )
    )
  }
  if (
    !is.null(
      token
    ) &&
      !authorized(
        request$headers$authorization,
        token
      )
  ) {
    return(
      http_response(
        401L,
        list(
          "WWW-Authenticate" = "Bearer"
        )
      )
    )
  }
  if (request$method != "POST") {
    return(
      http_response(
        405L,
        list(
          Allow = "POST"
        )
      )
    )
  }
  version <- request$headers[["mcp-protocol-version"]]
  if (!is.null(version) && version != "2025-11-25") {
    return(
      http_response(
        400L
      )
    )
  }
}

http_reply <- function(
  response
) {
  if (is.null(response)) {
    return(
      http_response(
        202L
      )
    )
  }
  http_response(
    if (is.null(response$id)) 400L else 200L,
    list(
      "Content-Type" = "application/json"
    ),
    as.character(
      json_line(
        response
      )
    )
  )
}

http_response <- function(
  status,
  headers = list(),
  body = ""
) {
  list(
    status = status,
    headers = headers,
    body = body
  )
}

local_origin <- function(
  origin
) {
  is.null(
    origin
  ) ||
    grepl(
      "^https?://(localhost|127[.]0[.]0[.]1|[[]::1[]])(:[0-9]+)?$",
      origin
    )
}

authorized <- function(
  header,
  token
) {
  is.character(
    header
  ) &&
    grepl(
      "^Bearer ",
      header,
      ignore.case = TRUE
    ) &&
    same_secret(
      substring(
        header,
        8
      ),
      token
    )
}

same_secret <- function(
  given,
  token
) {
  given <- charToRaw(
    given
  )
  token <- charToRaw(
    token
  )
  length(
    given
  ) ==
    length(
      token
    ) &&
    all(
      xor(
        given,
        token
      ) ==
        as.raw(
          0
        )
    )
}
