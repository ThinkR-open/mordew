http_request <- function(
  body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
  method = "POST",
  headers = list()
) {
  list(
    method = method,
    headers = headers,
    body = body
  )
}

test_that("handle_http() answers a request with its JSON-RPC response", {
  expect_identical(
    handle_http(
      http_request()
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

test_that("handle_http() accepts a notification with 202 and no body", {
  expect_identical(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","method":"notifications/initialized"}'
      )
    ),
    list(
      status = 202L,
      headers = list(),
      body = ""
    )
  )
})

test_that("handle_http() answers a body that is not JSON with 400", {
  response <- handle_http(
    http_request(
      "not json"
    )
  )

  expect_identical(
    response$status,
    400L
  )
  expect_identical(
    response$body,
    '{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}'
  )
})

test_that("handle_http() offers no SSE stream on GET", {
  expect_identical(
    handle_http(
      http_request(
        "",
        method = "GET"
      )
    ),
    list(
      status = 405L,
      headers = list(
        Allow = "POST"
      ),
      body = ""
    )
  )
})

test_that("handle_http() refuses a request from another origin", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          origin = "https://example.com"
        )
      )
    )$status,
    403L
  )
})

test_that("handle_http() answers a request from a local origin", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          origin = "http://localhost:6274"
        )
      )
    )$status,
    200L
  )
})

test_that("handle_http() refuses another protocol version", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          "mcp-protocol-version" = "2025-06-18"
        )
      )
    )$status,
    400L
  )
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          "mcp-protocol-version" = "2025-11-25"
        )
      )
    )$status,
    200L
  )
})
