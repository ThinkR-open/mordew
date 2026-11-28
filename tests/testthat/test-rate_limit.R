completion_request <- list(
  jsonrpc = "2.0",
  id = 1,
  method = "completion/complete"
)

test_that("a rate limit refuses the completion requests beyond its rate per second", {
  limit <- new_rate_limit(
    2
  )

  expect_null(
    limited_response(
      completion_request,
      limit
    )
  )
  expect_null(
    limited_response(
      completion_request,
      limit
    )
  )
  expect_equal(
    limited_response(
      completion_request,
      limit
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32603,
        message = "Too many completion requests: retry later."
      )
    )
  )
  limit$times <- limit$times - 1
  expect_null(
    limited_response(
      completion_request,
      limit
    )
  )
})

test_that("a rate limit lets the other requests through", {
  limit <- new_rate_limit(
    0
  )

  expect_null(
    limited_response(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "prompts/list"
      ),
      limit
    )
  )
  expect_null(
    limited_response(
      "completion/complete",
      limit
    )
  )
  expect_null(
    limited_response(
      completion_request,
      NULL
    )
  )
})
