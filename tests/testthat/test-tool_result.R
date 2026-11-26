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

test_that("tool_result() sends a list as JSON text content", {
  expect_equal(
    tool_result(
      list(
        runs = 12L,
        pace = 5.123456,
        years = c(
          2023,
          NA
        ),
        note = NULL
      ),
      "json"
    ),
    list(
      content = list(
        list(
          type = "text",
          text = "{\"runs\":12,\"pace\":5.123456,\"years\":[2023,null],\"note\":null}"
        )
      )
    )
  )
})

test_that("tool_result() rejects a data frame for @mcpReturns json", {
  expect_true(
    tool_result(
      data.frame(
        runs = 12
      ),
      "json"
    )$isError
  )
})

test_that("tool_result() sends a data frame as a markdown table", {
  expect_equal(
    tool_result(
      data.frame(
        surface = c(
          "road",
          "trail"
        ),
        runs = c(
          12L,
          3L
        )
      ),
      "table"
    )$content[[1]]$text,
    paste(
      "Rows: 2. Columns: 2.",
      "",
      "| surface | runs |",
      "| --- | --- |",
      "| road | 12 |",
      "| trail | 3 |",
      sep = "\n"
    )
  )
})

test_that("tool_result() truncates a table to its row limit", {
  expect_equal(
    tool_result(
      data.frame(
        runs = 1:3
      ),
      "table",
      rows = 2
    )$content[[1]]$text,
    paste(
      "Rows: 3 (first 2 shown). Columns: 1.",
      "",
      "| runs |",
      "| --- |",
      "| 1 |",
      "| 2 |",
      sep = "\n"
    )
  )
})

test_that("tool_result() truncates a table to 50 rows without a row limit", {
  expect_match(
    tool_result(
      data.frame(
        runs = 1:51
      ),
      "table",
      rows = NULL
    )$content[[1]]$text,
    "Rows: 51 (first 50 shown).",
    fixed = TRUE
  )
})

test_that("tool_result() escapes pipes in table cells", {
  expect_equal(
    tool_result(
      data.frame(
        note = "a|b"
      ),
      "table"
    )$content[[1]]$text,
    paste(
      "Rows: 1. Columns: 1.",
      "",
      "| note |",
      "| --- |",
      "| a\\|b |",
      sep = "\n"
    )
  )
})

test_that("tool_result() keeps the rows of a table with paste() argument names as columns", {
  expect_equal(
    tool_result(
      data.frame(
        sep = 1:2,
        collapse = c(
          "x",
          "y"
        )
      ),
      "table"
    )$content[[1]]$text,
    paste(
      "Rows: 2. Columns: 2.",
      "",
      "| sep | collapse |",
      "| --- | --- |",
      "| 1 | x |",
      "| 2 | y |",
      sep = "\n"
    )
  )
})

test_that("tool_result() sends a recorded plot as an 800x600 PNG at 96 dpi", {
  grDevices::pdf(
    NULL
  )
  grDevices::dev.control(
    "enable"
  )
  graphics::plot(
    1:3
  )
  plot <- grDevices::recordPlot()
  grDevices::dev.off()
  expect_equal(
    tool_result(
      plot,
      "image"
    )$content,
    list(
      list(
        type = "image",
        data = reference_png(
          function() {
            grDevices::replayPlot(
              plot
            )
          }
        ),
        mimeType = "image/png"
      )
    )
  )
})

test_that("tool_result() sends a ggplot as an 800x600 PNG at 96 dpi", {
  skip_if_not_installed(
    "ggplot2"
  )
  plot <- ggplot2::ggplot(
    data.frame(
      x = 1:3,
      y = 1:3
    ),
    ggplot2::aes(
      x,
      y
    )
  ) +
    ggplot2::geom_point()
  expect_equal(
    tool_result(
      plot,
      "image"
    )$content[[1]]$data,
    reference_png(
      function() {
        print(
          plot
        )
      }
    )
  )
})

test_that("tool_result() closes the PNG device when a plot fails", {
  skip_if_not_installed(
    "ggplot2"
  )
  devices <- grDevices::dev.list()
  plot <- ggplot2::ggplot(
    data.frame(
      x = 1:3
    ),
    ggplot2::aes(
      x,
      missing_column
    )
  ) +
    ggplot2::geom_point()
  expect_error(
    tool_result(
      plot,
      "image"
    )
  )
  expect_equal(
    grDevices::dev.list(),
    devices
  )
})
