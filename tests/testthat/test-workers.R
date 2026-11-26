whoami_package <- function(
  env = parent.frame()
) {
  local_tool_package(
    env,
    tools = c(
      "#' Who am I",
      "#'",
      "#' Gives the process ID of the R process that runs the tool.",
      "#'",
      "#' @mcpTool",
      "#' @mcpReturns text",
      "whoami <- function() {",
      "  as.character(Sys.getpid())",
      "}"
    )
  )
}

tool_call_body <- function(
  name,
  arguments = empty_object()
) {
  as.character(
    json_line(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = name,
          arguments = arguments
        )
      )
    )
  )
}

wait_for <- function(
  promise
) {
  value <- NULL
  promises::then(
    promise,
    onFulfilled = function(result) {
      value <<- result
    },
    onRejected = function(error) {
      value <<- error
    }
  )
  deadline <- Sys.time() + 30
  while (is.null(value) && Sys.time() < deadline) {
    later::run_now(
      0.1
    )
  }
  value
}

test_that("worker_respond() answers a message with the tools of the package", {
  skip_if_not_installed(
    "processx"
  )
  local_dev_package()

  expect_identical(
    worker_respond(
      tool_call_body(
        "echo",
        list(
          text = "trail"
        )
      ),
      "runlog",
      server_identity(
        "runlog"
      ),
      .libPaths()
    )$result$content[[1]]$text,
    "trail"
  )
})

test_that("http_app() runs a tool call in a worker and answers with a promise", {
  skip_if_not_installed(
    "mirai"
  )
  local_dev_package(
    whoami_package()
  )
  local_workers(
    1,
    "runlog"
  )
  namespace <- asNamespace(
    "runlog"
  )

  response <- wait_for(
    http_app(
      server_identity(
        "runlog"
      ),
      namespace$mordew_registry,
      namespace,
      new_pool(
        "runlog",
        1,
        60,
        0
      )
    )$call(
      rook_request(
        tool_call_body(
          "whoami"
        )
      )
    )
  )

  expect_identical(
    response$status,
    200L
  )
  expect_false(
    identical(
      jsonlite::fromJSON(
        response$body
      )$result$content$text,
      as.character(
        Sys.getpid()
      )
    )
  )
})

test_that("start_workers() loads an installed package in the workers", {
  skip_if_not_installed(
    "mirai"
  )
  local_install(
    whoami_package()
  )
  withr::defer(
    unloadNamespace(
      "runlog"
    )
  )
  local_workers(
    1,
    "runlog"
  )

  response <- in_worker(
    tool_call_body(
      "whoami"
    ),
    "runlog",
    server_identity(
      "runlog"
    ),
    60
  )[]
  pid <- response$result$content[[1]]$text

  expect_match(
    pid,
    "^[0-9]+$"
  )
  expect_false(
    identical(
      pid,
      as.character(
        Sys.getpid()
      )
    )
  )
})

test_that("handle_http() answers a body that is not JSON in the front, with workers", {
  expect_identical(
    handle_http(
      http_request(
        "not json"
      ),
      pool = new_pool(
        "runlog",
        1,
        60,
        0
      )
    )$status,
    400L
  )
})

tool_text <- function(
  response
) {
  jsonlite::fromJSON(
    response$body
  )$result$content$text
}

test_that("handle_http() answers busy when every worker runs a call and the queue is full", {
  pool <- new_pool(
    "runlog",
    1,
    60,
    1
  )
  pool$in_flight <- 1
  pool$waiting <- list(
    function() {
      NULL
    }
  )

  expect_identical(
    tool_text(
      handle_http(
        http_request(
          tool_call_body(
            "whoami"
          )
        ),
        pool = pool
      )
    ),
    "The server is busy: retry later."
  )
})

test_that("handle_http() stops a tool call that runs too long", {
  skip_if_not_installed(
    "mirai"
  )
  local_dev_package(
    local_tool_package(
      tools = c(
        "#' Wait",
        "#'",
        "#' Waits for some seconds.",
        "#'",
        "#' @param seconds Seconds to wait.",
        "#'",
        "#' @mcpTool",
        "#' @mcpType seconds type_number(min = 0)",
        "#' @mcpReturns text",
        "nap <- function(seconds) {",
        "  Sys.sleep(seconds)",
        "  \"Done.\"",
        "}"
      )
    )
  )
  local_workers(
    1,
    "runlog"
  )
  pool <- new_pool(
    "runlog",
    1,
    1,
    0
  )

  response <- wait_for(
    handle_http(
      http_request(
        tool_call_body(
          "nap",
          list(
            seconds = 10
          )
        )
      ),
      server_identity(
        "runlog"
      ),
      pool = pool
    )
  )

  expect_identical(
    tool_text(
      response
    ),
    "The tool did not finish within 1 seconds."
  )
  expect_identical(
    pool$in_flight,
    0
  )
})

test_that("handle_http() answers when the worker running a tool stops", {
  skip_if_not_installed(
    "mirai"
  )
  local_dev_package(
    local_tool_package(
      tools = c(
        "#' Quit",
        "#'",
        "#' Stops R.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "stop_r <- function() {",
        "  quit(save = \"no\", status = 1)",
        "}"
      )
    )
  )
  local_workers(
    1,
    "runlog"
  )

  response <- wait_for(
    handle_http(
      http_request(
        tool_call_body(
          "stop_r"
        )
      ),
      server_identity(
        "runlog"
      ),
      pool = new_pool(
        "runlog",
        1,
        60,
        0
      )
    )
  )

  expect_match(
    tool_text(
      response
    ),
    "^The worker running the tool stopped"
  )
})

nap_package <- function(
  env = parent.frame()
) {
  local_tool_package(
    env,
    tools = c(
      "#' Wait",
      "#'",
      "#' Waits for some seconds.",
      "#'",
      "#' @param seconds Seconds to wait.",
      "#'",
      "#' @mcpTool",
      "#' @mcpType seconds type_number(min = 0)",
      "#' @mcpReturns text",
      "nap <- function(seconds) {",
      "  Sys.sleep(seconds)",
      "  \"Done.\"",
      "}"
    )
  )
}

test_that("handle_http() queues a call until a worker is free, then times its run only", {
  skip_if_not_installed(
    "mirai"
  )
  local_dev_package(
    nap_package()
  )
  local_workers(
    1,
    "runlog"
  )
  pool <- new_pool(
    "runlog",
    1,
    1.5,
    1
  )
  call_nap <- function() {
    handle_http(
      http_request(
        tool_call_body(
          "nap",
          list(
            seconds = 1
          )
        )
      ),
      server_identity(
        "runlog"
      ),
      pool = pool
    )
  }

  first <- call_nap()
  second <- call_nap()
  queued <- length(
    pool$waiting
  )
  first <- wait_for(
    first
  )
  second <- wait_for(
    second
  )

  expect_identical(
    queued,
    1L
  )
  expect_identical(
    c(
      tool_text(
        first
      ),
      tool_text(
        second
      )
    ),
    c(
      "Done.",
      "Done."
    )
  )
  expect_identical(
    c(
      pool$in_flight,
      length(
        pool$waiting
      )
    ),
    c(
      0,
      0
    )
  )
})

test_that("handle_http() replaces a worker that stops", {
  skip_if_not_installed(
    "mirai"
  )
  local_install(
    local_tool_package(
      tools = c(
        "#' Quit",
        "#'",
        "#' Stops R.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "stop_r <- function() {",
        "  quit(save = \"no\", status = 1)",
        "}",
        "",
        "#' Who am I",
        "#'",
        "#' Gives the process ID of the R process that runs the tool.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "whoami <- function() {",
        "  as.character(Sys.getpid())",
        "}"
      )
    )
  )
  withr::defer(
    unloadNamespace(
      "runlog"
    )
  )
  local_workers(
    1,
    "runlog"
  )
  pool <- new_pool(
    "runlog",
    1,
    10,
    0
  )
  call_tool_over_http <- function(name) {
    wait_for(
      handle_http(
        http_request(
          tool_call_body(
            name
          )
        ),
        server_identity(
          "runlog"
        ),
        pool = pool
      )
    )
  }

  call_tool_over_http(
    "stop_r"
  )
  response <- call_tool_over_http(
    "whoami"
  )

  expect_match(
    tool_text(
      response
    ),
    "^[0-9]+$"
  )
})

test_that("the worker pool reads the fields of a message by their exact names", {
  pool <- new_pool(
    "runlog",
    1,
    60,
    1
  )
  pool$in_flight <- 1
  pool$waiting <- list(
    function() {
      NULL
    }
  )
  answer <- function(
    ...
  ) {
    jsonlite::fromJSON(
      handle_http(
        http_request(
          as.character(
            json_line(
              list(
                jsonrpc = "2.0",
                ...,
                params = list(
                  name = "whoami"
                )
              )
            )
          )
        ),
        pool = pool
      )$body
    )
  }

  expect_identical(
    answer(
      id = 1,
      methodx = "tools/call"
    )$error$code,
    -32600L
  )
  expect_null(
    answer(
      idx = 9,
      method = "tools/call"
    )$id
  )
})
