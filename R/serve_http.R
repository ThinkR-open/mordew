http_app <- function(
  server,
  registry,
  envir,
  pool = NULL,
  token = NULL
) {
  list(
    call = function(req) {
      handle_http(
        list(
          method = req$REQUEST_METHOD,
          path = req$PATH_INFO,
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
        pool,
        token
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
  queue,
  token
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
      ),
      token
    )
  )
}
