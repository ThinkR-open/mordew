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

test_that("handle_http() answers GET /health with 200", {
  expect_identical(
    handle_http(
      http_request(
        "",
        method = "GET",
        path = "/health"
      )
    ),
    list(
      status = 200L,
      headers = list(
        "Content-Type" = "application/json"
      ),
      body = '{"status":"ok"}'
    )
  )
})

test_that("handle_http() refuses a request without the token", {
  expect_identical(
    handle_http(
      http_request(),
      token = "s3cret"
    ),
    list(
      status = 401L,
      headers = list(
        "WWW-Authenticate" = "Bearer"
      ),
      body = ""
    )
  )
})

test_that("handle_http() refuses a request with another token", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          authorization = "Bearer s3cre"
        )
      ),
      token = "s3cret"
    )$status,
    401L
  )
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          authorization = "s3cret"
        )
      ),
      token = "s3cret"
    )$status,
    401L
  )
})

test_that("handle_http() answers a request with the token", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          authorization = "Bearer s3cret"
        )
      ),
      token = "s3cret"
    )$status,
    200L
  )
})

test_that("handle_http() keeps GET /health open with a token", {
  expect_identical(
    handle_http(
      http_request(
        "",
        method = "GET",
        path = "/health"
      ),
      token = "s3cret"
    )$status,
    200L
  )
})

test_that("handle_http() reads the headers by their exact names", {
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          authorizationx = "Bearer s3cret"
        )
      ),
      token = "s3cret"
    )$status,
    401L
  )
  expect_identical(
    handle_http(
      http_request(
        headers = list(
          originx = "http://evil.example"
        )
      )
    )$status,
    200L
  )
})

test_that("handle_http() answers 404 on a path that is neither /mcp nor /health", {
  expect_identical(
    vapply(
      c(
        "/",
        "/anything/else"
      ),
      function(path) {
        handle_http(
          http_request(
            path = path
          )
        )$status
      },
      integer(1),
      USE.NAMES = FALSE
    ),
    c(
      404L,
      404L
    )
  )
  expect_identical(
    handle_http(
      http_request(
        "",
        method = "GET",
        path = "/anything/else"
      )
    )$status,
    404L
  )
})

test_that("handle_http() answers 405 on /health for another method than GET", {
  expect_identical(
    handle_http(
      http_request(
        path = "/health"
      )
    ),
    list(
      status = 405L,
      headers = list(
        Allow = "GET"
      ),
      body = ""
    )
  )
})

test_that("handle_http() passes the resources to the request", {
  expect_identical(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","id":1,"method":"resources/list"}'
      ),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces"
          )
        )
      )
    )$body,
    '{"jsonrpc":"2.0","id":1,"result":{"resources":[{"uri":"runlog://surfaces","name":"surfaces"}]}}'
  )
})
