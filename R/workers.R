start_workers <- function(
  workers,
  package
) {
  path <- find.package(
    package
  )
  load <- if (
    from_source(
      path
    )
  ) {
    bquote(
      pkgload::load_all(
        .(path),
        quiet = TRUE
      )
    )
  } else {
    bquote(
      loadNamespace(
        .(package)
      )
    )
  }
  setup <- call(
    "{",
    call(
      ".libPaths",
      .libPaths()
    ),
    load
  )
  mirai::daemons(
    workers,
    dispatcher = TRUE
  )
  invisible(
    mirai::everywhere(
      setup
    )[]
  )
}

in_worker <- function(
  text,
  package,
  server
) {
  mirai::mirai(
    worker_respond(
      text,
      package,
      server
    ),
    worker_respond = worker_respond,
    text = text,
    package = package,
    server = server
  )
}

worker_respond <- function(
  text,
  package,
  server
) {
  namespace <- asNamespace(
    package
  )
  respond(
    text,
    server,
    namespace$mordew_registry,
    namespace
  )
}

is_tool_call <- function(
  text
) {
  message <- tryCatch(
    jsonlite::fromJSON(
      text,
      simplifyVector = FALSE
    ),
    error = function(error) {
      NULL
    }
  )
  is.list(
    message
  ) &&
    identical(
      message$method,
      "tools/call"
    )
}
