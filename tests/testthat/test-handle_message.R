summarise_runs_registry <- function(
  returns = "text",
  limit = NULL
) {
  list(
    summarise_runs = list(
      fun = "summarise_runs",
      tool = list(
        name = "summarise_runs",
        description = "Summarise runs by surface.",
        inputSchema = type_object(
          surface = type_string()
        )$schema
      ),
      returns = returns,
      limit = limit
    )
  )
}

test_that("handle_message() answers a ping with an empty result", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "ping"
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = structure(
        list(),
        names = character()
      )
    )
  )
})

test_that("handle_message() answers an unknown method with a JSON-RPC error", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "foo"
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32601,
        message = "Method not found: foo"
      )
    )
  )
})

test_that("handle_message() answers initialize with 2025-11-25 and the server identity", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "initialize",
        params = list(
          protocolVersion = "2025-06-18"
        )
      ),
      list(
        name = "runlog",
        version = "0.0.0.9000",
        instructions = "Answers questions about a running log."
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        protocolVersion = "2025-11-25",
        capabilities = list(
          tools = structure(
            list(),
            names = character()
          )
        ),
        serverInfo = list(
          name = "runlog",
          version = "0.0.0.9000"
        ),
        instructions = "Answers questions about a running log."
      )
    )
  )
})

test_that("handle_message() lists the tools of the registry as an array", {
  summarise_runs <- list(
    name = "summarise_runs",
    description = "Summarise runs by surface.",
    inputSchema = list(
      type = "object"
    )
  )
  list_runs <- list(
    name = "list_runs",
    description = "List runs of a year.",
    inputSchema = list(
      type = "object"
    )
  )

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/list"
      ),
      registry = list(
        summarise_runs = list(
          fun = "summarise_runs",
          tool = summarise_runs,
          returns = "text"
        ),
        list_runs = list(
          fun = "list_runs",
          tool = list_runs,
          returns = "table"
        )
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        tools = list(
          summarise_runs,
          list_runs
        )
      )
    )
  )
})

test_that("handle_message() answers an unknown tool with a JSON-RPC error", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "foo",
          arguments = list()
        )
      ),
      registry = list()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32602,
        message = "Unknown tool: foo"
      )
    )
  )
})

test_that("handle_message() answers a tool call without a name as invalid params", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          arguments = list()
        )
      ),
      registry = list()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32602,
        message = "Invalid params"
      )
    )
  )
})

test_that("handle_message() answers a tool call with a non-string name as invalid params", {
  summarise_runs <- function(
    surface
  ) {
    paste0(
      "12 runs on ",
      surface,
      "."
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = 1,
          arguments = list(
            surface = "trail"
          )
        )
      ),
      registry = summarise_runs_registry(),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32602,
        message = "Invalid params"
      )
    )
  )
})

test_that("handle_message() answers a tool call whose params are not an object as invalid params", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = "get_runs"
      ),
      registry = list()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32602,
        message = "Invalid params"
      )
    )
  )
})

test_that("handle_message() answers a tool call whose arguments have no names as invalid params", {
  get_runs <- function(
    year = 2025L
  ) {
    paste(
      "Runs of",
      year
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "get_runs",
          arguments = list(
            "not-a-year"
          )
        )
      ),
      registry = list(
        get_runs = list(
          fun = "get_runs",
          tool = list(
            name = "get_runs",
            description = "List the runs of a year.",
            inputSchema = type_object(
              year = type_integer(
                required = FALSE
              )
            )$schema
          ),
          returns = "text"
        )
      ),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32602,
        message = "Invalid params"
      )
    )
  )
})

test_that("handle_message() calls a tool and sends its result", {
  summarise_runs <- function(
    surface
  ) {
    paste0(
      "12 runs on ",
      surface,
      "."
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "summarise_runs",
          arguments = list(
            surface = "trail"
          )
        )
      ),
      registry = summarise_runs_registry(),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "12 runs on trail."
          )
        )
      )
    )
  )
})

test_that("handle_message() calls a tool without arguments", {
  count_runs <- function() {
    "42 runs."
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "count_runs"
        )
      ),
      registry = list(
        count_runs = list(
          fun = "count_runs",
          tool = list(
            name = "count_runs",
            description = "Count all runs.",
            inputSchema = type_object()$schema
          ),
          returns = "text"
        )
      ),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "42 runs."
          )
        )
      )
    )
  )
})

test_that("handle_message() passes a JSON array to the tool as an R vector", {
  total_distance <- function(
    distances
  ) {
    as.character(
      sum(
        distances
      )
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "total_distance",
          arguments = list(
            distances = list(
              10.5,
              21.1
            )
          )
        )
      ),
      registry = list(
        total_distance = list(
          fun = "total_distance",
          tool = list(
            name = "total_distance",
            description = "Add up distances.",
            inputSchema = type_object(
              distances = type_array(
                type_number()
              )
            )$schema
          ),
          returns = "text"
        )
      ),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "31.6"
          )
        )
      )
    )
  )
})

test_that("handle_message() sends a tool error as an isError result", {
  summarise_runs <- function(
    surface
  ) {
    stop(
      "No runs on ",
      surface,
      "."
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "summarise_runs",
          arguments = list(
            surface = "beach"
          )
        )
      ),
      registry = summarise_runs_registry(),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "No runs on beach."
          )
        ),
        isError = TRUE
      )
    )
  )
})

test_that("handle_message() sends invalid arguments as an isError result", {
  summarise_runs <- function(
    surface
  ) {
    paste0(
      "12 runs on ",
      surface,
      "."
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "summarise_runs",
          arguments = list(
            surface = 12
          )
        )
      ),
      registry = summarise_runs_registry(),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "Argument `surface` must be of type string."
          )
        ),
        isError = TRUE
      )
    )
  )
})

test_that("handle_message() sends a serialisation error as an isError result", {
  summarise_runs <- function(
    surface
  ) {
    list(
      surface = surface,
      cache = new.env()
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "summarise_runs",
          arguments = list(
            surface = "trail"
          )
        )
      ),
      registry = summarise_runs_registry(
        returns = "json"
      ),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = "No method asJSON S3 class: environment"
          )
        ),
        isError = TRUE
      )
    )
  )
})

test_that("handle_message() sends a table within the tool row limit", {
  summarise_runs <- function(
    surface
  ) {
    data.frame(
      surface = c(
        "road",
        "trail",
        "track"
      )
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "summarise_runs",
          arguments = list(
            surface = "trail"
          )
        )
      ),
      registry = summarise_runs_registry(
        returns = "table",
        limit = list(
          rows = 2
        )
      ),
      envir = environment()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        content = list(
          list(
            type = "text",
            text = paste0(
              "Rows: 3 (first 2 shown). Columns: 1.\n\n",
              "| surface |\n",
              "| --- |\n",
              "| road |\n",
              "| trail |"
            )
          )
        )
      )
    )
  )
})

test_that("handle_message() answers a request without a method as invalid", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32600,
        message = "Invalid Request"
      )
    )
  )
})

test_that("handle_message() answers a request with a non-string method as invalid", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = 1
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32600,
        message = "Invalid Request"
      )
    )
  )
})

test_that("handle_message() answers a message that is not a JSON object as invalid", {
  invalid <- list(
    jsonrpc = "2.0",
    id = NULL,
    error = list(
      code = -32600,
      message = "Invalid Request"
    )
  )

  expect_equal(
    handle_message(
      1
    ),
    invalid
  )
  expect_equal(
    handle_message(
      list(
        list(
          jsonrpc = "2.0",
          id = 1,
          method = "ping"
        )
      )
    ),
    invalid
  )
})

test_that("handle_message() does not answer a notification", {
  expect_null(
    handle_message(
      list(
        jsonrpc = "2.0",
        method = "notifications/initialized"
      )
    )
  )
})

test_that("handle_message() reads the fields of a message by their exact names", {
  summarise_runs <- function(
    surface
  ) {
    paste0(
      "12 runs on ",
      surface,
      "."
    )
  }
  call <- function(
    params
  ) {
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = params
      ),
      registry = summarise_runs_registry(),
      envir = environment()
    )
  }

  expect_null(
    handle_message(
      list(
        jsonrpc = "2.0",
        idx = 9,
        method = "ping"
      )
    )
  )
  expect_identical(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        methodx = "ping"
      )
    )$error$code,
    -32600
  )
  expect_identical(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        paramsx = list(
          name = "summarise_runs"
        )
      ),
      registry = summarise_runs_registry()
    )$error$message,
    "Invalid params"
  )
  expect_identical(
    call(
      list(
        namex = "summarise_runs"
      )
    )$error$message,
    "Invalid params"
  )
  expect_true(
    call(
      list(
        name = "summarise_runs",
        argumentsx = list(
          surface = "trail"
        )
      )
    )$result$isError
  )
  expect_true(
    call(
      list(
        name = "summarise_runs",
        argumentsx = list(
          "trail"
        )
      )
    )$result$isError
  )
})
