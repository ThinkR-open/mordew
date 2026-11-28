test_that("http_app() answers the requests httpuv receives", {
  expect_identical(
    http_app()$call(
      rook_request()
    ),
    list(
      status = 200L,
      headers = list(
        "Content-Type" = "application/json"
      ),
      body = '{"jsonrpc":"2.0","id":1,"result":{}}'
    )
  )
})

test_that("http_app() reads the headers httpuv receives", {
  expect_identical(
    http_app()$call(
      rook_request(
        headers = c(
          origin = "https://example.com"
        )
      )
    )$status,
    403L
  )
})

test_that("http_app() reads the path httpuv receives", {
  expect_identical(
    http_app()$call(
      rook_request(
        "",
        method = "GET",
        path = "/health"
      )
    )$status,
    200L
  )
})

test_that("http_app() refuses a request on its headers, without reading the body", {
  request <- rook_request()
  request$rook.input$read <- function() {
    stop(
      "The body was read."
    )
  }

  expect_identical(
    http_app(
      token = "s3cret"
    )$onHeaders(
      request
    )$status,
    401L
  )
})

test_that("http_app() lets httpuv go on with a request its headers allow", {
  expect_null(
    http_app()$onHeaders(
      rook_request()
    )
  )
})

test_that("serve_http() starts the workers, then runs the app with httpuv", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      started <<- list(
        workers = workers,
        package = package
      )
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      list(
        host = host,
        port = port,
        status = app$call(
          rook_request()
        )$status
      )
    },
    .package = "httpuv"
  )
  started <- NULL

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL
    ),
    list(
      host = "127.0.0.1",
      port = 8000,
      status = 200L
    )
  )
  expect_identical(
    started,
    list(
      workers = 4,
      package = "mordew"
    )
  )
})

test_that("serve_http() asks for the token", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request()
      )$status
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      "s3cret"
    ),
    401L
  )
})

test_that("http_app() refuses a body larger than 4 MB on its headers", {
  request <- function(
    length
  ) {
    request <- rook_request(
      headers = c(
        "content-type" = "application/json",
        "content-length" = length
      )
    )
    request$rook.input$read <- function() {
      stop(
        "The body was read."
      )
    }
    request
  }

  expect_identical(
    http_app()$onHeaders(
      request(
        "4194305"
      )
    ),
    list(
      status = 413L,
      headers = list(),
      body = ""
    )
  )
  expect_null(
    http_app()$onHeaders(
      request(
        "4194304"
      )
    )
  )
})

test_that("http_app() passes the resources to the request", {
  expect_identical(
    http_app(
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces"
          )
        )
      )
    )$call(
      rook_request(
        '{"jsonrpc":"2.0","id":1,"method":"resources/list"}'
      )
    )$body,
    '{"jsonrpc":"2.0","id":1,"result":{"resources":[{"uri":"runlog://surfaces","name":"surfaces"}]}}'
  )
})

test_that("serve_http() serves the resources of the package", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"resources/list"}'
        )
      )$body
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL
    ),
    '{"jsonrpc":"2.0","id":1,"result":{"resources":[]}}'
  )
})

test_that("http_app() passes the prompts to the request", {
  expect_identical(
    http_app(
      prompts = list(
        review_run = list(
          fun = "review_run",
          prompt = list(
            name = "review_run"
          )
        )
      )
    )$call(
      rook_request(
        '{"jsonrpc":"2.0","id":1,"method":"prompts/list"}'
      )
    )$body,
    '{"jsonrpc":"2.0","id":1,"result":{"prompts":[{"name":"review_run"}]}}'
  )
})

test_that("serve_http() serves the prompts of the package", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"prompts/list"}'
        )
      )$body
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL
    ),
    '{"jsonrpc":"2.0","id":1,"result":{"prompts":[]}}'
  )
})

test_that("serve_http() limits the completion requests to their rate per second", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"completion/complete"}'
        )
      )$body
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL,
      0,
      10
    ),
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"Too many completion requests: retry later."}}'
  )
})

test_that("serve_http() limits the tool calls to their rate per second", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"echo"}}'
        )
      )$body
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL,
      10,
      0
    ),
    '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"Too many tool calls: retry later."}],"isError":true}}'
  )
})


test_that("serve_http() keeps the tasks of the server", {
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"tasks/get","params":{"taskId":"nope"}}'
        )
      )$body
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "mordew",
      4,
      60,
      8,
      NULL
    ),
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"Failed to retrieve task: Task not found"}}'
  )
})

test_that("serve_http() runs the tasks of the package in the background", {
  local_dev_package(
    local_tool_package(
      tools = c(
        "#' Totals",
        "#'",
        "#' Totals of the log.",
        "#'",
        "#' @mcpTool",
        "#' @mcpReturns text",
        "#' @mcpTask optional",
        "totals <- function() {",
        "  \"12 runs\"",
        "}"
      )
    )
  )
  started <- NULL
  local_mocked_bindings(
    start_workers = function(
      workers,
      package
    ) {
      NULL
    },
    task_mirai = function(
      text,
      package,
      server
    ) {
      started <<- package
      list(
        data = NULL
      )
    }
  )
  local_mocked_bindings(
    runServer = function(
      host,
      port,
      app
    ) {
      app$call(
        rook_request(
          '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"totals","task":{}}}'
        )
      )$status
    },
    .package = "httpuv"
  )

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      "runlog",
      4,
      60,
      8,
      NULL
    ),
    200L
  )
  expect_identical(
    started,
    "runlog"
  )
})
