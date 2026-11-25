rook_request <- function(
  body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
  method = "POST",
  headers = c(
    "content-type" = "application/json"
  )
) {
  list(
    REQUEST_METHOD = method,
    HEADERS = headers,
    rook.input = list(
      read = function() {
        charToRaw(
          body
        )
      }
    )
  )
}

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

test_that("serve_http() runs the app with httpuv on the host and port", {
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

  expect_identical(
    serve_http(
      "127.0.0.1",
      8000,
      NULL,
      NULL,
      NULL
    ),
    list(
      host = "127.0.0.1",
      port = 8000,
      status = 200L
    )
  )
})
