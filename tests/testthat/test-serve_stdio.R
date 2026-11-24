test_that("serve_stdio() answers each request on its own line", {
  input <- withr::local_connection(
    textConnection(
      c(
        '{"jsonrpc":"2.0","id":1,"method":"ping"}',
        '{"jsonrpc":"2.0","id":2,"method":"ping"}'
      )
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output
  )

  expect_equal(
    readLines(
      path
    ),
    c(
      '{"jsonrpc":"2.0","id":1,"result":{}}',
      '{"jsonrpc":"2.0","id":2,"result":{}}'
    )
  )
})

test_that("serve_stdio() writes nothing for a notification", {
  input <- withr::local_connection(
    textConnection(
      c(
        '{"jsonrpc":"2.0","method":"notifications/initialized"}',
        '{"jsonrpc":"2.0","id":1,"method":"ping"}'
      )
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output
  )

  expect_equal(
    readLines(
      path
    ),
    '{"jsonrpc":"2.0","id":1,"result":{}}'
  )
})

test_that("serve_stdio() answers a line that is not JSON with a parse error", {
  input <- withr::local_connection(
    textConnection(
      c(
        "not json",
        '{"jsonrpc":"2.0","id":1,"method":"ping"}'
      )
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output
  )

  expect_equal(
    readLines(
      path
    ),
    c(
      '{"jsonrpc":"2.0","id":null,"error":{"code":-32700,"message":"Parse error"}}',
      '{"jsonrpc":"2.0","id":1,"result":{}}'
    )
  )
})

test_that("serve_stdio() writes numbers without rounding them", {
  input <- withr::local_connection(
    textConnection(
      '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output,
    registry = list(
      share_runs = list(
        fun = "share_runs",
        tool = list(
          name = "share_runs",
          description = "Share of runs above a pace.",
          inputSchema = type_object(
            share = type_number(
              min = 0.123456
            )
          )$schema
        ),
        returns = "text"
      )
    )
  )

  expect_match(
    readLines(
      path
    ),
    '"minimum":0.123456',
    fixed = TRUE
  )
})

test_that("serve_stdio() answers a JSON null as an invalid request", {
  input <- withr::local_connection(
    textConnection(
      "null"
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output
  )

  expect_equal(
    readLines(
      path
    ),
    '{"jsonrpc":"2.0","id":null,"error":{"code":-32600,"message":"Invalid Request"}}'
  )
})

test_that("serve_stdio() keeps UTF-8 text intact in a C locale", {
  echo <- function(
    text
  ) {
    text
  }
  input_path <- withr::local_tempfile()
  writeBin(
    charToRaw(
      paste0(
        '{"jsonrpc":"2.0","id":1,"method":"tools/call",',
        '"params":{"name":"echo","arguments":{"text":"Café ☕"}}}\n'
      )
    ),
    input_path
  )
  withr::local_locale(
    c(
      LC_CTYPE = "C"
    )
  )
  input <- withr::local_connection(
    file(
      input_path,
      "r"
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  serve_stdio(
    input,
    output,
    registry = list(
      echo = list(
        fun = "echo",
        tool = list(
          name = "echo",
          description = "Send the text back.",
          inputSchema = type_object(
            text = type_string()
          )$schema
        ),
        returns = "text"
      )
    ),
    envir = environment()
  )

  expect_equal(
    readLines(
      path,
      encoding = "UTF-8"
    ),
    paste0(
      '{"jsonrpc":"2.0","id":1,"result":{"content":',
      '[{"type":"text","text":"Café ☕"}]}}'
    )
  )
})

test_that("serve_stdio() sends what a tool prints to stderr", {
  chatty <- function() {
    print(
      "debug"
    )
    "done"
  }
  input <- withr::local_connection(
    textConnection(
      '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"chatty"}}'
    )
  )
  path <- withr::local_tempfile()
  output <- withr::local_connection(
    file(
      path,
      "w"
    )
  )

  expect_equal(
    capture.output(
      serve_stdio(
        input,
        output,
        registry = list(
          chatty = list(
            fun = "chatty",
            tool = list(
              name = "chatty",
              description = "Print, then answer.",
              inputSchema = type_object()$schema
            ),
            returns = "text"
          )
        ),
        envir = environment()
      ),
      type = "message"
    ),
    '[1] "debug"'
  )
  expect_equal(
    readLines(
      path
    ),
    '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":"done"}]}}'
  )
})
