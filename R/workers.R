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

new_pool <- function(
  package,
  workers,
  timeout,
  queue
) {
  list2env(
    list(
      package = package,
      workers = workers,
      timeout = timeout,
      queue = queue,
      in_flight = 0,
      waiting = list()
    )
  )
}

pool_call <- function(
  pool,
  message,
  text,
  server
) {
  if (pool$in_flight < pool$workers) {
    return(
      run_in_pool(
        pool,
        message,
        text,
        server
      )
    )
  }
  if (
    length(
      pool$waiting
    ) >=
      pool$queue
  ) {
    return(
      http_reply(
        tool_failure(
          message$id,
          "The server is busy: retry later."
        )
      )
    )
  }
  promises::promise(
    function(resolve, reject) {
      pool$waiting <- c(
        pool$waiting,
        function() {
          resolve(
            run_in_pool(
              pool,
              message,
              text,
              server
            )
          )
        }
      )
    }
  )
}

run_in_pool <- function(
  pool,
  message,
  text,
  server
) {
  pool$in_flight <- pool$in_flight + 1
  promises::finally(
    promises::then(
      in_worker(
        text,
        pool$package,
        server,
        pool$timeout
      ),
      onFulfilled = http_reply,
      onRejected = function(error) {
        http_reply(
          tool_failure(
            message$id,
            worker_failure(
              error,
              pool$timeout
            )
          )
        )
      }
    ),
    onFinally = function() {
      pool$in_flight <- pool$in_flight - 1
      if (
        length(
          pool$waiting
        ) >
          0
      ) {
        next_call <- pool$waiting[[1]]
        pool$waiting <- pool$waiting[-1]
        next_call()
      }
    }
  )
}

worker_failure <- function(
  error,
  timeout
) {
  if (
    startsWith(
      conditionMessage(
        error
      ),
      "5 |"
    )
  ) {
    return(
      paste0(
        "The tool did not finish within ",
        timeout,
        " seconds."
      )
    )
  }
  paste0(
    "The worker running the tool stopped: ",
    conditionMessage(
      error
    )
  )
}

tool_failure <- function(
  id,
  text
) {
  rpc_response(
    id,
    list(
      result = error_result(
        text
      )
    )
  )
}

in_worker <- function(
  text,
  package,
  server,
  timeout
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
    server = server,
    .timeout = timeout * 1000
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

tool_call_message <- function(
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
  if (
    is.list(
      message
    ) &&
      identical(
        message$method,
        "tools/call"
      )
  ) {
    message
  }
}
