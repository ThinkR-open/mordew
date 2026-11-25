http_app <- function(
  server,
  registry,
  envir,
  package = NULL
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
        envir,
        package
      )
    }
  )
}

serve_http <- function(
  host,
  port,
  package,
  workers
) {
  start_workers(
    workers,
    package
  )
  on.exit(
    mirai::daemons(
      0
    )
  )
  namespace <- asNamespace(
    package
  )
  httpuv::runServer(
    host,
    port,
    http_app(
      server_identity(
        package
      ),
      namespace$mordew_registry,
      namespace,
      package
    )
  )
}
