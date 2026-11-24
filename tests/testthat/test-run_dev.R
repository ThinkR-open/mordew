fake_chat <- function() {
  chat <- new.env()
  chat$get_system_prompt <- function() {
    "You answer questions about running."
  }
  chat$set_system_prompt <- function(value) {
    chat$system_prompt <- value
  }
  chat$set_tools <- function(tools) {
    chat$tools <- tools
  }
  chat
}

test_that("ellmer_tools() turns the server's tools into ellmer tools", {
  skip_if_not_installed(
    "ellmer"
  )
  skip_if_not_installed(
    "processx"
  )
  local_mordew_lib()
  connection <- start_server(
    "runlog",
    local_tool_package()
  )
  withr::defer(
    client_stop(
      connection
    )
  )

  tools <- ellmer_tools(
    connection
  )

  expect_equal(
    vapply(
      tools,
      function(tool) {
        tool@name
      },
      character(1)
    ),
    c(
      "echo",
      "fail_always"
    )
  )
  expect_equal(
    tools[[1]]@arguments@properties$text@json,
    list(
      type = "string",
      description = "Text to send back."
    )
  )
  expect_true(
    tools[[1]]@arguments@properties$text@required
  )
  expect_equal(
    tools[[1]](
      text = "trail"
    ),
    "trail"
  )
  expect_error(
    tools[[2]](),
    "No runs today."
  )
})

test_that("tool_text() tells the model about an image it cannot see", {
  expect_equal(
    tool_text(
      list(
        content = list(
          list(
            type = "text",
            text = "Runs per month."
          ),
          list(
            type = "image",
            data = "iVBORw0KGgo=",
            mimeType = "image/png"
          )
        )
      )
    ),
    paste0(
      "Runs per month.\n",
      "[The tool returned an image/png image, which ellmer sends to the ",
      "model as text only.]"
    )
  )
})

test_that("run_dev() chats with the development version of the package", {
  skip_if_not_installed(
    "ellmer"
  )
  skip_if_not_installed(
    "processx"
  )
  local_mordew_lib()
  path <- local_tool_package()
  chat <- fake_chat()
  local_mocked_bindings(
    live_console = function(chat, quiet = FALSE) {
      chat$echoed <- chat$tools[[1]](
        text = "trail"
      )
    },
    .package = "ellmer"
  )

  run_dev(
    chat = chat,
    pkg = path
  )

  expect_equal(
    chat$echoed,
    "trail"
  )
  expect_equal(
    chat$system_prompt,
    c(
      "You answer questions about running.",
      "Describe what this server does, and when the model should use its tools."
    )
  )
})

test_that("run_dev() can open ellmer's browser UI", {
  skip_if_not_installed(
    "ellmer"
  )
  skip_if_not_installed(
    "processx"
  )
  local_mordew_lib()
  chat <- fake_chat()
  local_mocked_bindings(
    live_browser = function(chat, quiet = FALSE) {
      chat$ui <- "browser"
    },
    .package = "ellmer"
  )

  run_dev(
    chat = chat,
    ui = "browser",
    pkg = local_tool_package()
  )

  expect_equal(
    chat$ui,
    "browser"
  )
})
