test_that("run_mcp_server() serves the tools of an installed package", {
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  dir.create(
    file.path(
      path,
      "R"
    ),
    showWarnings = FALSE
  )
  writeLines(
    'mordew_registry <- list(echo = list(fun = "echo"))',
    file.path(
      path,
      "R",
      "mordew_registry.R"
    )
  )
  local_install(
    path
  )
  withr::defer(
    unloadNamespace(
      "runlog"
    )
  )
  local_mocked_bindings(
    serve_stdio = function(
      input,
      output,
      server,
      registry,
      envir
    ) {
      list(
        server = server,
        registry = registry,
        envir = envir
      )
    }
  )

  served <- run_mcp_server(
    "runlog"
  )

  expect_equal(
    served$server,
    server_identity(
      "runlog"
    )
  )
  expect_equal(
    served$registry,
    list(
      echo = list(
        fun = "echo"
      )
    )
  )
  expect_identical(
    served$envir,
    asNamespace(
      "runlog"
    )
  )
})

test_that("run_mcp_server() serves the tools over HTTP on a local port by default", {
  local_mocked_bindings(
    serve_http = function(
      host,
      port,
      package,
      workers,
      timeout,
      queue,
      token
    ) {
      list(
        host = host,
        port = port,
        package = package,
        workers = workers,
        timeout = timeout,
        queue = queue,
        token = token
      )
    }
  )
  withr::local_envvar(
    MORDEW_TOKEN = NA
  )

  expect_identical(
    run_mcp_server(
      "mordew",
      transport = "http"
    ),
    list(
      host = "127.0.0.1",
      port = 8000,
      package = "mordew",
      workers = 4,
      timeout = 60,
      queue = 8,
      token = NULL
    )
  )
})

test_that("run_mcp_server() takes the token from MORDEW_TOKEN", {
  local_mocked_bindings(
    serve_http = function(
      host,
      port,
      package,
      workers,
      timeout,
      queue,
      token
    ) {
      token
    }
  )
  withr::local_envvar(
    MORDEW_TOKEN = "s3cret"
  )

  expect_identical(
    run_mcp_server(
      "mordew",
      transport = "http"
    ),
    "s3cret"
  )
})

test_that("run_mcp_server() refuses to serve beyond this machine without a token", {
  local_mocked_bindings(
    serve_http = function(
      ...
    ) {
      "served"
    }
  )
  withr::local_envvar(
    MORDEW_TOKEN = NA
  )

  expect_error(
    run_mcp_server(
      "mordew",
      transport = "http",
      host = "0.0.0.0"
    ),
    "Set a token to serve on 0.0.0.0",
    fixed = TRUE
  )
})

test_that("a generated package serves its tools to a client over stdio", {
  skip_on_cran()
  skip_if_not_installed(
    "processx"
  )
  local_install(
    local_tool_package()
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
      "-e",
      paste0(
        ".libPaths(",
        paste(
          deparse(
            .libPaths()
          ),
          collapse = ""
        ),
        "); runlog::run_mcp_server()"
      )
    )
  )
  withr::defer(
    client_stop(
      client
    )
  )

  expect_equal(
    client$server$serverInfo$name,
    "runlog"
  )
  expect_equal(
    client_request(
      client,
      "tools/list"
    )$result$tools[[1]]$name,
    "echo"
  )
  expect_equal(
    client_request(
      client,
      "tools/call",
      list(
        name = "echo",
        arguments = list(
          text = "trail"
        )
      )
    )$result$content[[1]]$text,
    "trail"
  )
})

test_that("a generated package serves its tools to a client over HTTP", {
  skip_on_cran()
  skip_if_not_installed(
    "processx"
  )
  skip_if_not_installed(
    "curl"
  )
  local_install(
    local_tool_package()
  )
  port <- httpuv::randomPort()
  server <- processx::process$new(
    rscript(),
    c(
      "--no-init-file",
      "-e",
      paste0(
        ".libPaths(",
        paste(
          deparse(
            .libPaths()
          ),
          collapse = ""
        ),
        "); runlog::run_mcp_server(transport = \"http\", workers = 1, port = ",
        port,
        ")"
      )
    )
  )
  withr::defer(
    server$kill()
  )
  post <- function(message) {
    handle <- curl::new_handle(
      postfields = json_line(
        message
      )
    )
    curl::handle_setheaders(
      handle,
      "Content-Type" = "application/json",
      Accept = "application/json, text/event-stream"
    )
    jsonlite::fromJSON(
      rawToChar(
        curl::curl_fetch_memory(
          paste0(
            "http://127.0.0.1:",
            port,
            "/mcp"
          ),
          handle
        )$content
      ),
      simplifyVector = FALSE
    )
  }
  deadline <- Sys.time() + 30
  while (
    inherits(
      try(
        post(
          list(
            jsonrpc = "2.0",
            id = 0,
            method = "ping"
          )
        ),
        silent = TRUE
      ),
      "try-error"
    ) &&
      Sys.time() < deadline
  ) {
    Sys.sleep(
      0.2
    )
  }

  expect_equal(
    post(
      list(
        jsonrpc = "2.0",
        id = 1,
        method = "tools/call",
        params = list(
          name = "echo",
          arguments = list(
            text = "trail é"
          )
        )
      )
    )$result$content[[1]]$text,
    "trail é"
  )
  expect_identical(
    curl::curl_fetch_memory(
      paste0(
        "http://127.0.0.1:",
        port,
        "/health"
      )
    )$status_code,
    200L
  )
})
