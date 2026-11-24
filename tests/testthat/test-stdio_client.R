initialized <- paste0(
  '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-11-25",',
  '"capabilities":{"tools":{}},"serverInfo":{"name":"fake","version":"1.0.0"}}}'
)

fake_server <- function(
  ...,
  timeout = 10,
  env = parent.frame()
) {
  skip_if_not_installed(
    "processx"
  )
  script <- withr::local_tempfile(
    fileext = ".R",
    .local_envir = env
  )
  writeLines(
    c(
      'input <- file("stdin", open = "r")',
      "reply <- function(line) {",
      "  writeLines(line)",
      "  flush(stdout())",
      "}",
      ...
    ),
    script
  )
  client <- stdio_client(
    file.path(
      R.home(
        "bin"
      ),
      "Rscript"
    ),
    c(
      "--no-init-file",
      script
    ),
    timeout = timeout
  )
  withr::defer(
    client_stop(
      client
    ),
    envir = env
  )
  client
}

answer_initialize <- c(
  "readLines(input, n = 1)",
  sprintf(
    "reply(%s)",
    deparse(
      initialized
    )
  ),
  "readLines(input, n = 1)"
)

test_that("stdio_client() opens an MCP 2025-11-25 session", {
  received <- withr::local_tempfile()
  client <- fake_server(
    "first <- readLines(input, n = 1)",
    sprintf(
      "reply(%s)",
      deparse(
        initialized
      )
    ),
    "second <- readLines(input, n = 1)",
    sprintf(
      "writeLines(c(first, second), %s)",
      deparse(
        received
      )
    ),
    "readLines(input)"
  )

  client_stop(
    client
  )
  messages <- lapply(
    readLines(
      received
    ),
    jsonlite::fromJSON,
    simplifyVector = FALSE
  )

  expect_equal(
    client$server$serverInfo$name,
    "fake"
  )
  expect_equal(
    messages[[1]]$method,
    "initialize"
  )
  expect_equal(
    messages[[1]]$params$protocolVersion,
    "2025-11-25"
  )
  expect_equal(
    messages[[1]]$params$clientInfo$name,
    "mordew"
  )
  expect_equal(
    messages[[2]],
    list(
      jsonrpc = "2.0",
      method = "notifications/initialized"
    )
  )
})

test_that("client_request() returns the response carrying its id", {
  client <- fake_server(
    answer_initialize,
    "readLines(input, n = 1)",
    "reply('{\"jsonrpc\":\"2.0\",\"id\":7,\"result\":{}}')",
    "reply('{\"jsonrpc\":\"2.0\",\"method\":\"notifications/message\"}')",
    "reply('not json')",
    "reply('{\"jsonrpc\":\"2.0\",\"id\":2,\"result\":{\"tools\":[]}}')",
    "readLines(input)"
  )

  expect_equal(
    client_request(
      client,
      "tools/list"
    ),
    list(
      jsonrpc = "2.0",
      id = 2L,
      result = list(
        tools = list()
      )
    )
  )
})

test_that("client_request() reassembles a response sent in pieces", {
  client <- fake_server(
    answer_initialize,
    "readLines(input, n = 1)",
    "cat('{\"jsonrpc\":\"2.0\",\"id\":2,')",
    "flush(stdout())",
    "Sys.sleep(0.5)",
    "reply('\"result\":{}}')",
    "readLines(input)"
  )

  expect_equal(
    client_request(
      client,
      "ping"
    )$id,
    2L
  )
})

test_that("client_request() sends a request larger than the pipe buffer", {
  client <- fake_server(
    answer_initialize,
    "line <- readLines(input, n = 1)",
    paste0(
      "reply(sprintf('{\"jsonrpc\":\"2.0\",\"id\":2,\"result\":{\"bytes\":%d}}', ",
      "nchar(line, 'bytes')))"
    ),
    "readLines(input)"
  )

  expect_gt(
    client_request(
      client,
      "tools/call",
      list(
        name = "echo",
        arguments = list(
          text = strrep(
            "a",
            1e6
          )
        )
      )
    )$result$bytes,
    1e6
  )
})

test_that("client_request() fails when the server does not answer in time", {
  client <- fake_server(
    answer_initialize,
    "readLines(input, n = 1)",
    "Sys.sleep(30)",
    timeout = 1
  )

  expect_error(
    client_request(
      client,
      "tools/list"
    ),
    "The server did not answer `tools/list` within 1 seconds."
  )
})

test_that("client_request() reports a server that stops while it is sent a request", {
  client <- fake_server(
    answer_initialize,
    "message('gone')",
    "quit(status = 1)"
  )

  expect_error(
    client_request(
      client,
      "tools/call",
      list(
        text = strrep(
          "a",
          1e6
        )
      )
    ),
    "The server stopped.\ngone"
  )
})

test_that("client_request() fails when the server does not read a request in time", {
  client <- fake_server(
    answer_initialize,
    "Sys.sleep(30)",
    timeout = 1
  )

  expect_error(
    client_request(
      client,
      "tools/call",
      list(
        text = strrep(
          "a",
          1e6
        )
      )
    ),
    "The server did not answer `tools/call` within 1 seconds."
  )
})

test_that("stdio_client() reports what the server wrote to stderr when it stops", {
  expect_error(
    fake_server(
      "message('boom')",
      "quit(status = 1)"
    ),
    "The server stopped.\nboom"
  )
})

test_that("stdio_client() refuses a server that answers another protocol version", {
  expect_error(
    fake_server(
      "readLines(input, n = 1)",
      sprintf(
        "reply(%s)",
        deparse(
          sub(
            "2025-11-25",
            "2025-06-18",
            initialized
          )
        )
      ),
      "readLines(input)"
    ),
    "The server does not speak MCP 2025-11-25"
  )
})

test_that("client_stop() stops the server", {
  client <- fake_server(
    answer_initialize,
    "readLines(input)"
  )

  client_stop(
    client
  )

  expect_false(
    client$process$is_alive()
  )
})
