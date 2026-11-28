new_task_store <- function(
  start,
  wait,
  running = 8,
  max_ttl = 3600000
) {
  list2env(
    list(
      start = start,
      wait = wait,
      running = running,
      max_ttl = max_ttl,
      tasks = list()
    )
  )
}

task_response <- function(
  message,
  text,
  registry,
  store
) {
  if (
    is.null(store) ||
      !is.list(message) ||
      !is.character(message[["method"]])
  ) {
    return(
      NULL
    )
  }
  params <- message[["params"]]
  if (identical(message[["method"]], "tools/call")) {
    entry <- if (is.list(params) && !is.null(params[["task"]])) {
      entry_of(
        registry,
        params[["name"]]
      )
    }
    if (is.null(entry)) {
      return(
        NULL
      )
    }
    return(
      rpc_response(
        message[["id"]],
        new_task(
          store,
          entry,
          params,
          text
        )
      )
    )
  }
  if (!message[["method"]] %in% c("tasks/get", "tasks/result", "tasks/cancel")) {
    return(
      NULL
    )
  }
  purge_tasks(
    store
  )
  task <- if (is.list(params)) {
    entry_of(
      store$tasks,
      params[["taskId"]]
    )
  }
  if (is.null(task)) {
    return(
      rpc_response(
        message[["id"]],
        rpc_error(
          -32602,
          "Failed to retrieve task: Task not found"
        )
      )
    )
  }
  refresh_task(
    task
  )
  body <- switch(
    message[["method"]],
    "tasks/get" = list(
      result = task_view(
        task
      )
    ),
    "tasks/result" = task_result(
      task,
      store
    ),
    "tasks/cancel" = cancel_task(
      task
    )
  )
  if (promises::is.promise(body)) {
    return(
      promises::then(
        body,
        function(body) {
          rpc_response(
            message[["id"]],
            body
          )
        }
      )
    )
  }
  rpc_response(
    message[["id"]],
    body
  )
}

new_task <- function(
  store,
  entry,
  params,
  text
) {
  if (
    !isTRUE(
      entry$tool$execution$taskSupport %in%
        c(
          "optional",
          "required"
        )
    )
  ) {
    return(
      rpc_error(
        -32601,
        paste0(
          "Tool `",
          params[["name"]],
          "` does not run as a task."
        )
      )
    )
  }
  purge_tasks(
    store
  )
  working <- vapply(
    store$tasks,
    function(task) {
      refresh_task(
        task
      )
      task$status == "working"
    },
    logical(1)
  )
  if (sum(working) >= store$running) {
    return(
      rpc_error(
        -32603,
        "Too many tasks running: retry later."
      )
    )
  }
  now <- Sys.time()
  task <- list2env(
    list(
      id = nanonext::random(
        16
      ),
      status = "working",
      created = now,
      updated = now,
      ttl = task_ttl(
        if (is.list(params[["task"]])) params[["task"]][["ttl"]],
        store$max_ttl
      ),
      handle = store$start(
        text
      )
    )
  )
  store$tasks[[task$id]] <- task
  list(
    result = list(
      task = task_view(
        task
      )
    )
  )
}

task_ttl <- function(
  requested,
  max_ttl
) {
  if (is.numeric(requested) && length(requested) == 1 && requested > 0) {
    return(
      min(
        requested,
        max_ttl
      )
    )
  }
  max_ttl
}

task_view <- function(
  task
) {
  Filter(
    Negate(
      is.null
    ),
    list(
      taskId = task$id,
      status = task$status,
      statusMessage = task$message,
      createdAt = iso_time(
        task$created
      ),
      lastUpdatedAt = iso_time(
        task$updated
      ),
      ttl = task$ttl,
      pollInterval = 1000
    )
  )
}

refresh_task <- function(
  task
) {
  if (task$status == "working" && !mirai::unresolved(task$handle)) {
    settle_task(
      task,
      task$handle$data
    )
  }
}

settle_task <- function(
  task,
  value
) {
  task$updated <- Sys.time()
  if (mirai::is_error_value(value)) {
    task$status <- "failed"
    task$message <- paste0(
      "The worker running the tool stopped: ",
      trimws(
        as.character(
          value
        )
      )
    )
    task$outcome <- rpc_error(
      -32603,
      task$message
    )
    return(
      invisible()
    )
  }
  task$outcome <- Filter(
    Negate(
      is.null
    ),
    value[c(
      "result",
      "error"
    )]
  )
  failed <- !is.null(value$error) || isTRUE(value$result$isError)
  task$status <- if (failed) "failed" else "completed"
  task$message <- if (!is.null(value$error)) {
    value$error$message
  } else if (failed) {
    value$result$content[[1]]$text
  }
}

task_result <- function(
  task,
  store
) {
  if (task$status == "working") {
    return(
      store$wait(
        task$handle,
        function() {
          refresh_task(
            task
          )
          task_payload(
            task
          )
        }
      )
    )
  }
  task_payload(
    task
  )
}

task_payload <- function(
  task
) {
  if (task$status == "cancelled") {
    return(
      rpc_error(
        -32603,
        "The task was cancelled."
      )
    )
  }
  if (!is.null(task$outcome$error)) {
    return(
      task$outcome
    )
  }
  list(
    result = c(
      task$outcome$result,
      list(
        `_meta` = list(
          "io.modelcontextprotocol/related-task" = list(
            taskId = task$id
          )
        )
      )
    )
  )
}

cancel_task <- function(
  task
) {
  if (task$status != "working") {
    return(
      rpc_error(
        -32602,
        paste0(
          "Cannot cancel task: already in terminal status '",
          task$status,
          "'"
        )
      )
    )
  }
  mirai::stop_mirai(
    task$handle
  )
  task$status <- "cancelled"
  task$updated <- Sys.time()
  list(
    result = task_view(
      task
    )
  )
}

purge_tasks <- function(
  store
) {
  now <- Sys.time()
  expired <- vapply(
    store$tasks,
    function(task) {
      as.numeric(
        difftime(
          now,
          task$created,
          units = "secs"
        )
      ) *
        1000 >
        task$ttl
    },
    logical(1)
  )
  for (task in store$tasks[expired]) {
    refresh_task(
      task
    )
    if (task$status == "working") {
      mirai::stop_mirai(
        task$handle
      )
    }
  }
  store$tasks <- store$tasks[!expired]
}

wait_blocking <- function(
  handle,
  then
) {
  mirai::call_mirai(
    handle
  )
  then()
}

wait_promise <- function(
  handle,
  then
) {
  promises::then(
    promises::as.promise(
      handle
    ),
    onFulfilled = function(value) {
      then()
    },
    onRejected = function(error) {
      then()
    }
  )
}

task_mirai <- function(
  text,
  package,
  server
) {
  share_libpaths()
  libs <- .libPaths()
  mirai::mirai(
    {
      .libPaths(
        libs
      )
      if (!isNamespaceLoaded(package)) {
        eval(
          load
        )
      }
      worker_respond(
        text,
        package,
        server,
        libs
      )
    },
    load = package_load(
      package
    ),
    worker_respond = worker_respond,
    text = text,
    package = package,
    server = server,
    libs = libs
  )
}

iso_time <- function(
  time
) {
  format(
    time,
    "%Y-%m-%dT%H:%M:%SZ",
    tz = "UTC"
  )
}
