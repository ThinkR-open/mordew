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

test_that("handle_http() passes the prompts to the request", {
  expect_identical(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","id":1,"method":"prompts/list"}'
      ),
      prompts = list(
        review_run = list(
          fun = "review_run",
          prompt = list(
            name = "review_run"
          )
        )
      )
    )$body,
    '{"jsonrpc":"2.0","id":1,"result":{"prompts":[{"name":"review_run"}]}}'
  )
})

test_that("handle_http() answers the completion requests beyond its rate limit before the workers", {
  expect_identical(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","id":1,"method":"completion/complete"}'
      ),
      pool = list(),
      limits = rate_limits(
        0,
        0,
        20
      )
    )$body,
    '{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"Too many completion requests: retry later."}}'
  )
})

task_registry <- list(
  totals = list(
    fun = "totals",
    tool = list(
      name = "totals",
      execution = list(
        taskSupport = "optional"
      )
    ),
    returns = "text"
  )
)

test_that("handle_http() creates the task of a tool call before the workers", {
  expect_match(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"totals","task":{}}}'
      ),
      registry = task_registry,
      pool = list(),
      tasks = new_task_store(
        start = function(text) {
          list(
            data = NULL
          )
        },
        wait = function(handle, then) {
          then()
        }
      )
    )$body,
    '"status":"working"',
    fixed = TRUE
  )
})

test_that("handle_http() answers a task result it waits for with a promise", {
  tasks <- new_task_store(
    start = function(text) {
      list(
        data = list(
          jsonrpc = "2.0",
          id = 1,
          result = list(
            content = list(),
            isError = FALSE
          )
        )
      )
    },
    wait = wait_promise
  )
  tasks$tasks$abc <- list2env(
    list(
      id = "abc",
      status = "working",
      created = Sys.time(),
      updated = Sys.time(),
      ttl = 60000,
      handle = mirai::mirai(
        {
          Sys.sleep(
            1
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
    )
  )

  response <- wait_for(
    handle_http(
      http_request(
        '{"jsonrpc":"2.0","id":2,"method":"tasks/result","params":{"taskId":"abc"}}'
      ),
      tasks = tasks
    )
  )

  expect_match(
    response$body,
    '"isError":false',
    fixed = TRUE
  )
})
