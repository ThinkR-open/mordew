http_app <- function(
  server,
  registry,
  envir,
  pool = NULL
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
        pool
      )
    }
  )
}

serve_http <- function(
  host,
  port,
  package,
  workers,
  timeout,
  queue
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
      new_pool(
        package,
        workers,
        timeout,
        queue
      )
    )
  )
}
