http_app <- function(
  server,
  registry,
  envir,
  pool = NULL,
  token = NULL,
  resources,
  prompts,
  limits = NULL
) {
  list(
    onHeaders = function(req) {
      reply_from_headers(
        request_head(
          req
        ),
        token
      )
    },
    call = function(req) {
      request <- request_head(
        req
      )
      request$body <- rawToChar(
        req$rook.input$read()
      )
      handle_http(
        request,
        server,
        registry,
        envir,
        pool,
        token,
        resources,
        prompts,
        limits
      )
    }
  )
}

request_head <- function(
  req
) {
  list(
    method = req$REQUEST_METHOD,
    path = req$PATH_INFO,
    headers = as.list(
      req$HEADERS
    )
  )
}

serve_http <- function(
  host,
  port,
  package,
  workers,
  timeout,
  queue,
  token,
  completions = 10,
  tool_calls = 10
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
      token,
      namespace$mordew_resources,
      namespace$mordew_prompts,
      rate_limits(
        completions,
        tool_calls
      )
    )
  )
}
