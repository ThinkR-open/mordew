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
    function(result) {
      value <<- result
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
      )
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
  start_workers(
    1,
    "runlog"
  )
  withr::defer(
    mirai::daemons(
      0
    )
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
      "runlog"
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
  start_workers(
    1,
    "runlog"
  )
  withr::defer(
    mirai::daemons(
      0
    )
  )

  response <- in_worker(
    tool_call_body(
      "whoami"
    ),
    "runlog",
    server_identity(
      "runlog"
    )
  )[]

  expect_false(
    identical(
      response$result$content[[1]]$text,
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
      package = "runlog"
    )$status,
    400L
  )
})
