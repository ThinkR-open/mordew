handle_http <- function(
  request,
  server,
  registry,
  envir
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
  response <- respond(
    request$body,
    server,
    registry,
    envir
  )
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
