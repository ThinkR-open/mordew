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
          ),
          resources = structure(
            list(),
            names = character()
          ),
          prompts = structure(
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

test_that("handle_message() lists no resources when there are none", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/list"
      ),
      resources = list()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        resources = list()
      )
    )
  )
})

test_that("handle_message() lists the resources as an array", {
  runs <- list(
    uri = "runlog://runs",
    name = "runs",
    description = "Every run of the log.",
    mimeType = "text/markdown"
  )
  surfaces <- list(
    uri = "runlog://surfaces",
    name = "surfaces",
    description = "The surfaces a run can be on.",
    mimeType = "text/plain"
  )

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/list"
      ),
      resources = list(
        "runlog://runs" = list(
          fun = "runs",
          resource = runs
        ),
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = surfaces
        )
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        resources = list(
          runs,
          surfaces
        )
      )
    )
  )
})

test_that("handle_message() lists the resource templates apart from the resources", {
  surfaces <- list(
    uri = "runlog://surfaces",
    name = "surfaces"
  )
  runs <- list(
    uriTemplate = "runlog://runs/{year}",
    name = "runs"
  )
  resources <- list(
    "runlog://surfaces" = list(
      fun = "surfaces",
      resource = surfaces
    ),
    "runlog://runs/{year}" = list(
      fun = "runs",
      resource = runs
    )
  )
  list_message <- function(
    method
  ) {
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = method
      ),
      resources = resources
    )$result
  }

  expect_equal(
    list_message(
      "resources/list"
    ),
    list(
      resources = list(
        surfaces
      )
    )
  )
  expect_equal(
    list_message(
      "resources/templates/list"
    ),
    list(
      resourceTemplates = list(
        runs
      )
    )
  )
})

read_runs <- function(
  uri,
  resources = list(
    "runlog://runs/{year}" = list(
      fun = "runs",
      resource = list(
        uriTemplate = "runlog://runs/{year}",
        name = "runs",
        mimeType = "text/plain"
      ),
      returns = "text"
    )
  )
) {
  runs <- function(year) {
    paste(
      "Runs of",
      year
    )
  }
  latest <- function() {
    "Latest runs"
  }
  handle_message(
    list(
      jsonrpc = "2.0",
      id = 1,
      method = "resources/read",
      params = list(
        uri = uri
      )
    ),
    envir = environment(),
    resources = resources
  )
}

test_that("handle_message() reads a resource template with the values of its URI", {
  expect_equal(
    read_runs(
      "runlog://runs/2024"
    )$result$contents,
    list(
      list(
        uri = "runlog://runs/2024",
        mimeType = "text/plain",
        text = "Runs of 2024"
      )
    )
  )
})

test_that("handle_message() matches a template variable to one segment of the URI", {
  expect_equal(
    read_runs(
      "runlog://runs/2024/extra"
    )$error,
    list(
      code = -32002,
      message = "Resource not found: runlog://runs/2024/extra"
    )
  )
})

test_that("handle_message() reads a resource before a template that matches its URI", {
  expect_equal(
    read_runs(
      "runlog://runs/latest",
      list(
        "runlog://runs/{year}" = list(
          fun = "runs",
          resource = list(
            uriTemplate = "runlog://runs/{year}",
            name = "runs",
            mimeType = "text/plain"
          ),
          returns = "text"
        ),
        "runlog://runs/latest" = list(
          fun = "latest",
          resource = list(
            uri = "runlog://runs/latest",
            name = "latest",
            mimeType = "text/plain"
          ),
          returns = "text"
        )
      )
    )$result$contents[[1]]$text,
    "Latest runs"
  )
})

test_that("handle_message() answers an unknown resource with a JSON-RPC error", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://shoes"
        )
      ),
      resources = list()
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32002,
        message = "Resource not found: runlog://shoes"
      )
    )
  )
})

test_that("handle_message() answers a resource read without a uri as invalid params", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          urix = "runlog://surfaces"
        )
      ),
      resources = list()
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

test_that("handle_message() answers a resource read whose params are not an object as invalid params", {
  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = "runlog://surfaces"
      ),
      resources = list()
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

test_that("handle_message() answers a resource that fails with an internal error", {
  surfaces <- function() {
    stop("No surfaces today.")
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "text/plain"
          ),
          returns = "text"
        )
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32603,
        message = "No surfaces today."
      )
    )
  )
})

test_that("handle_message() answers a resource that does not return text with an internal error", {
  surfaces <- function() {
    data.frame(
      surface = "road"
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "text/plain"
          ),
          returns = "text"
        )
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      error = list(
        code = -32603,
        message = "The resource returns text, but returned class data.frame."
      )
    )
  )
})

test_that("handle_message() sends a resource of several lines as one text", {
  surfaces <- function() {
    c(
      "road",
      "trail",
      "track"
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "text/plain"
          ),
          returns = "text"
        )
      )
    )$result$contents[[1]][["text"]],
    "road\ntrail\ntrack"
  )
})

test_that("handle_message() reads a resource and sends its text", {
  surfaces <- function() {
    "road, trail, track"
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "text/plain"
          ),
          returns = "text"
        )
      )
    ),
    list(
      jsonrpc = "2.0",
      id = 1,
      result = list(
        contents = list(
          list(
            uri = "runlog://surfaces",
            mimeType = "text/plain",
            text = "road, trail, track"
          )
        )
      )
    )
  )
})

test_that("handle_message() sends a table resource as markdown", {
  surfaces <- function() {
    data.frame(
      surface = "road"
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "text/markdown"
          ),
          returns = "table"
        )
      )
    )$result$contents,
    list(
      list(
        uri = "runlog://surfaces",
        mimeType = "text/markdown",
        text = "Rows: 1. Columns: 1.\n\n| surface |\n| --- |\n| road |"
      )
    )
  )
})

test_that("handle_message() sends a JSON resource as text", {
  surfaces <- function() {
    list(
      surfaces = c(
        "road",
        "trail"
      )
    )
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://surfaces"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://surfaces" = list(
          fun = "surfaces",
          resource = list(
            uri = "runlog://surfaces",
            name = "surfaces",
            mimeType = "application/json"
          ),
          returns = "json"
        )
      )
    )$result$contents,
    list(
      list(
        uri = "runlog://surfaces",
        mimeType = "application/json",
        text = '{"surfaces":["road","trail"]}'
      )
    )
  )
})

test_that("handle_message() sends an image resource as a base64 PNG blob", {
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
  elevation <- function() {
    plot
  }

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "resources/read",
        params = list(
          uri = "runlog://elevation"
        )
      ),
      envir = environment(),
      resources = list(
        "runlog://elevation" = list(
          fun = "elevation",
          resource = list(
            uri = "runlog://elevation",
            name = "elevation",
            mimeType = "image/png"
          ),
          returns = "image"
        )
      )
    )$result$contents,
    list(
      list(
        uri = "runlog://elevation",
        mimeType = "image/png",
        blob = reference_png(
          function() {
            grDevices::replayPlot(
              plot
            )
          }
        )
      )
    )
  )
})

get_review <- function(
  params = list(
    name = "review_run",
    arguments = list(
      run_id = "42"
    )
  ),
  review_run = function(run_id, tone = "kind") {
    paste(
      "Review run",
      run_id,
      "in a",
      tone,
      "tone."
    )
  }
) {
  handle_message(
    list(
      jsonrpc = "2.0",
      id = 1,
      method = "prompts/get",
      params = params
    ),
    envir = environment(),
    prompts = list(
      review_run = list(
        fun = "review_run",
        prompt = list(
          name = "review_run",
          arguments = list(
            list(
              name = "run_id",
              required = TRUE
            ),
            list(
              name = "tone",
              required = FALSE
            )
          )
        )
      )
    )
  )
}

test_that("handle_message() lists the prompts", {
  review_run <- list(
    name = "review_run",
    arguments = list()
  )

  expect_equal(
    handle_message(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "prompts/list"
      ),
      prompts = list(
        review_run = list(
          fun = "review_run",
          prompt = review_run
        )
      )
    )$result,
    list(
      prompts = list(
        review_run
      )
    )
  )
})

test_that("handle_message() gets a prompt as a user message, with its arguments", {
  expect_equal(
    get_review()$result,
    list(
      messages = list(
        list(
          role = "user",
          content = list(
            type = "text",
            text = "Review run 42 in a kind tone."
          )
        )
      )
    )
  )
})

test_that("handle_message() answers an unknown prompt as invalid params", {
  expect_equal(
    get_review(
      list(
        name = "nope"
      )
    )$error,
    list(
      code = -32602,
      message = "Unknown prompt: nope"
    )
  )
})

test_that("handle_message() answers invalid prompt arguments as invalid params", {
  arguments_error <- function(
    arguments
  ) {
    get_review(
      list(
        name = "review_run",
        arguments = arguments
      )
    )$error
  }

  expect_equal(
    arguments_error(
      list()
    ),
    list(
      code = -32602,
      message = "Missing argument `run_id`."
    )
  )
  expect_equal(
    arguments_error(
      list(
        run_id = "42",
        distance = "10"
      )
    ),
    list(
      code = -32602,
      message = "Unknown argument `distance`."
    )
  )
  expect_equal(
    arguments_error(
      list(
        run_id = 42
      )
    ),
    list(
      code = -32602,
      message = "Argument `run_id` must be of type string."
    )
  )
})

test_that("handle_message() answers a prompt get without a name as invalid params", {
  expect_equal(
    get_review(
      list(
        arguments = list()
      )
    )$error,
    list(
      code = -32602,
      message = "Invalid params"
    )
  )
  expect_equal(
    get_review(
      list(
        name = "review_run",
        arguments = list(
          "42"
        )
      )
    )$error,
    list(
      code = -32602,
      message = "Invalid params"
    )
  )
})

test_that("handle_message() answers a prompt that fails or does not return text with an internal error", {
  expect_equal(
    get_review(
      review_run = function(run_id) {
        stop("No runs today.")
      }
    )$error,
    list(
      code = -32603,
      message = "No runs today."
    )
  )
  expect_equal(
    get_review(
      review_run = function(run_id) {
        42
      }
    )$error,
    list(
      code = -32603,
      message = "The prompt returns text, but returned class numeric."
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
