http_app <- function(
  server,
  registry,
  envir
) {
  list(
    call = function(req) {
      handle_http(
        list(
          method = req$REQUEST_METHOD,
          headers = as.list(
            req$HEADERS
          ),
          body = rawToChar(
            req$rook.input$read()
          )
        ),
        server,
        registry,
        envir
      )
    }
  )
}

serve_http <- function(
  host,
  port,
  server,
  registry,
  envir
) {
  httpuv::runServer(
    host,
    port,
    http_app(
      server,
      registry,
      envir
    )
  )
}
