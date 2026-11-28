completion_request <- list(
  jsonrpc = "2.0",
  id = 1,
  method = "completion/complete"
)

test_that("rate limits refuse the completion requests beyond their rate per second", {
  limits <- rate_limits(
    2,
    10
  )

  expect_null(
    limited_response(
      completion_request,
      limits
    )
  )
  expect_null(
    limited_response(
      completion_request,
      limits
    )
  )
  expect_equal(
    limited_response(
      completion_request,
      limits
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
  limits[["completion/complete"]]$times <- limits[["completion/complete"]]$times - 1
  expect_null(
    limited_response(
      completion_request,
      limits
    )
  )
})

test_that("rate limits refuse the tool calls beyond their rate per second with an error result", {
  expect_equal(
    limited_response(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call"
      ),
      rate_limits(
        10,
        0
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "Too many tool calls: retry later."
          )
        ),
        isError = TRUE
      )
    )
  )
})

test_that("rate limits let the other requests through", {
  limits <- rate_limits(
    0,
    0
  )

  expect_null(
    limited_response(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "prompts/list"
      ),
      limits
    )
  )
  expect_null(
    limited_response(
      "completion/complete",
      limits
    )
  )
  expect_null(
    limited_response(
      completion_request,
      NULL
    )
  )
})
