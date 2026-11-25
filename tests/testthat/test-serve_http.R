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
      8
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
