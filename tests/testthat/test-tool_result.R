test_that("tool_result() sends a text value as text content", {
  expect_equal(
    tool_result(
      "12 runs on trail in 2023.",
      "text"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "12 runs on trail in 2023."
        )
      )
    )
  )
})

test_that("tool_result() sends an error as an isError result", {
  expect_equal(
    tool_result(
      simpleError(
        "Missing argument `surface`."
      ),
      "text"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "Missing argument `surface`."
        )
      ),
      isError = TRUE
    )
  )
})

test_that("tool_result() rejects a value that does not match @mcpReturns", {
  expect_equal(
    tool_result(
      data.frame(
        runs = 12
      ),
      "text"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "The tool declares @mcpReturns text, but returned class data.frame."
        )
      ),
      isError = TRUE
    )
  )
})
