tool_registry <- function(
  support = "optional"
) {
  list(
    totals = list(
      fun = "totals",
      tool = list(
        name = "totals",
        execution = if (!is.null(support)) {
          list(
            taskSupport = support
          )
        }
      ),
      returns = "text"
    )
  )
}

task_call <- function(
  ttl = NULL
) {
  list(
    jsonrpc = "2.0",
    id = 1,
    method = "tools/call",
    params = list(
      name = "totals",
      task = Filter(
        Negate(
          is.null
        ),
        list(
          ttl = ttl
        )
      )
    )
  )
}

done <- function(
  body = list(
    result = list(
      content = list(
        list(
          type = "text",
          text = "12 runs"
        )
      ),
      isError = FALSE
    )
  )
) {
  rpc_response(
    1,
    body
  )
}

resolved_store <- function(
  value = done(),
  running = 8
) {
  new_task_store(
    start = function(text) {
      list(
        data = value
      )
    },
    wait = function(handle, then) {
      then()
    },
    running = running
  )
}

create_task <- function(
  store,
  ttl = NULL,
  registry = tool_registry()
) {
  task_response(
    task_call(
      ttl
    ),
    json_line(
      task_call(
        ttl
      )
    ),
    registry,
    store
  )
}

task_request <- function(
  store,
  method,
  task_id
) {
  task_response(
    list(
      jsonrpc = "2.0",
      id = 2,
      method = method,
      params = list(
        taskId = task_id
      )
    ),
    "",
    tool_registry(),
    store
  )
}

test_that("a tool call with a task creates a working task and starts the call", {
  started <- NULL
  store <- new_task_store(
    start = function(text) {
      started <<- text
      list(
        data = done()
      )
    },
    wait = function(handle, then) {
      then()
    }
  )

  task <- create_task(
    store,
    60000
  )$result$task

  expect_identical(
    task$status,
    "working"
  )
  expect_match(
    task$taskId,
    "^[0-9a-f]{32}$"
  )
  expect_identical(
    task[c(
      "ttl",
      "pollInterval"
    )],
    list(
      ttl = 60000,
      pollInterval = 1000
    )
  )
  expect_match(
    c(
      task$createdAt,
      task$lastUpdatedAt
    ),
    "^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$"
  )
  expect_identical(
    started,
    json_line(
      task_call(
        60000
      )
    )
  )
})

test_that("the ttl of a task is the one asked, at most an hour", {
  store <- resolved_store()

  expect_identical(
    c(
      create_task(
        store
      )$result$task$ttl,
      create_task(
        store,
        7200000
      )$result$task$ttl
    ),
    c(
      3600000,
      3600000
    )
  )
})

test_that("a tool that does not run as a task refuses a call with a task", {
  refusal <- list(
    code = -32601,
    message = "Tool `totals` does not run as a task."
  )

  expect_equal(
    create_task(
      resolved_store(),
      registry = tool_registry(
        NULL
      )
    )$error,
    refusal
  )
  expect_equal(
    create_task(
      resolved_store(),
      registry = tool_registry(
        "forbidden"
      )
    )$error,
    refusal
  )
})

test_that("a call with a task to an unknown tool is left to the tool call", {
  expect_null(
    create_task(
      resolved_store(),
      registry = list()
    )
  )
})

test_that("tasks/get tells whether a task completed or failed", {
  status <- function(
    value
  ) {
    store <- resolved_store(
      value
    )
    result <- task_request(
      store,
      "tasks/get",
      create_task(
        store
      )$result$task$taskId
    )$result
    list(
      status = result$status,
      statusMessage = result$statusMessage
    )
  }

  expect_equal(
    status(
      done()
    ),
    list(
      status = "completed",
      statusMessage = NULL
    )
  )
  expect_equal(
    status(
      done(
        list(
          result = list(
            content = list(
              list(
                type = "text",
                text = "No runs today."
              )
            ),
            isError = TRUE
          )
        )
      )
    ),
    list(
      status = "failed",
      statusMessage = "No runs today."
    )
  )
  expect_equal(
    status(
      done(
        rpc_error(
          -32602,
          "Unknown tool: totals"
        )
      )
    ),
    list(
      status = "failed",
      statusMessage = "Unknown tool: totals"
    )
  )
  expect_equal(
    status(
      structure(
        "boom",
        class = c(
          "errorValue",
          "try-error"
        )
      )
    ),
    list(
      status = "failed",
      statusMessage = "The worker running the tool stopped: boom"
    )
  )
})

test_that("tasks/result sends the result of the call, tied to its task", {
  store <- resolved_store()
  id <- create_task(
    store
  )$result$task$taskId

  expect_equal(
    task_request(
      store,
      "tasks/result",
      id
    ),
    list(
      jsonrpc = "2.0",
      id = 2,
      result = list(
        content = list(
          list(
            type = "text",
            text = "12 runs"
          )
        ),
        isError = FALSE,
        `_meta` = list(
          "io.modelcontextprotocol/related-task" = list(
            taskId = id
          )
        )
      )
    )
  )
})

test_that("tasks/result sends the error of a call that ended in a JSON-RPC error", {
  store <- resolved_store(
    done(
      rpc_error(
        -32602,
        "Unknown tool: totals"
      )
    )
  )

  expect_equal(
    task_request(
      store,
      "tasks/result",
      create_task(
        store
      )$result$task$taskId
    )$error,
    list(
      code = -32602,
      message = "Unknown tool: totals"
    )
  )
})

test_that("tasks/result waits for a task that is still working", {
  store <- new_task_store(
    start = function(text) {
      mirai::mirai(
        {
          Sys.sleep(
            0.5
          )
          list(
            jsonrpc = "2.0",
            id = 1,
            result = list(
              content = list(),
              isError = FALSE
            )
          )
        }
      )
    },
    wait = wait_blocking
  )
  id <- create_task(
    store
  )$result$task$taskId

  expect_false(
    task_request(
      store,
      "tasks/result",
      id
    )$result$isError
  )
  expect_identical(
    task_request(
      store,
      "tasks/get",
      id
    )$result$status,
    "completed"
  )
})

test_that("tasks/cancel stops a working task, which stays cancelled", {
  store <- new_task_store(
    start = function(text) {
      mirai::mirai(
        Sys.sleep(
          10
        )
      )
    },
    wait = wait_blocking
  )
  id <- create_task(
    store
  )$result$task$taskId

  expect_identical(
    task_request(
      store,
      "tasks/cancel",
      id
    )$result$status,
    "cancelled"
  )
  expect_identical(
    task_request(
      store,
      "tasks/get",
      id
    )$result$status,
    "cancelled"
  )
  expect_equal(
    task_request(
      store,
      "tasks/result",
      id
    )$error,
    list(
      code = -32603,
      message = "The task was cancelled."
    )
  )
})

test_that("tasks/cancel refuses a task that has ended", {
  store <- resolved_store()

  expect_equal(
    task_request(
      store,
      "tasks/cancel",
      create_task(
        store
      )$result$task$taskId
    )$error,
    list(
      code = -32602,
      message = "Cannot cancel task: already in terminal status 'completed'"
    )
  )
})

test_that("an unknown or expired task is not found", {
  store <- resolved_store()
  id <- create_task(
    store
  )$result$task$taskId
  store$tasks[[id]]$created <- Sys.time() - 7200
  not_found <- list(
    code = -32602,
    message = "Failed to retrieve task: Task not found"
  )

  for (method in c("tasks/get", "tasks/result", "tasks/cancel")) {
    expect_equal(
      task_request(
        store,
        method,
        "nope"
      )$error,
      not_found
    )
  }
  expect_equal(
    task_request(
      store,
      "tasks/get",
      id
    )$error,
    not_found
  )
})

test_that("a task beyond the tasks that may run at once is refused", {
  expect_equal(
    create_task(
      resolved_store(
        running = 0
      )
    )$error,
    list(
      code = -32603,
      message = "Too many tasks running: retry later."
    )
  )
})

test_that("task_response() leaves the other requests alone", {
  store <- resolved_store()

  expect_null(
    task_response(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "totals"
        )
      ),
      "",
      tool_registry(),
      store
    )
  )
  expect_null(
    task_response(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "prompts/list"
      ),
      "",
      tool_registry(),
      store
    )
  )
  expect_null(
    task_response(
      "tasks/get",
      "",
      tool_registry(),
      store
    )
  )
  expect_null(
    task_response(
      task_call(),
      "",
      tool_registry(),
      NULL
    )
  )
})

test_that("a task waits by blocking over stdio and with a promise over HTTP", {
  expect_identical(
    wait_blocking(
      mirai::mirai(
        1
      ),
      function() {
        "done"
      }
    ),
    "done"
  )
  expect_identical(
    wait_for(
      wait_promise(
        mirai::mirai(
          1
        ),
        function() {
          "done"
        }
      )
    ),
    "done"
  )
})

test_that("an expired task that still runs is stopped", {
  handle <- mirai::mirai(
    Sys.sleep(
      10
    )
  )
  store <- new_task_store(
    start = function(text) {
      handle
    },
    wait = wait_blocking
  )
  id <- create_task(
    store
  )$result$task$taskId
  store$tasks[[id]]$created <- Sys.time() - 7200

  expect_equal(
    task_request(
      store,
      "tasks/get",
      id
    )$error$code,
    -32602
  )
  expect_false(
    mirai::unresolved(
      handle
    )
  )
})

test_that("a task waiting with a promise goes on when its call fails", {
  expect_identical(
    wait_for(
      wait_promise(
        mirai::mirai(
          stop(
            "boom"
          )
        ),
        function() {
          "done"
        }
      )
    ),
    "done"
  )
})
