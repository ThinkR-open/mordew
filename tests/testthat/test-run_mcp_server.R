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

test_that("a generated package serves its tools to a client over stdio", {
  skip_on_cran()
  path <- file.path(
    tempfile(),
    "runlog"
  )
  create_mordew(
    path
  )
  tool <- c(
    "#' Echo the text",
    "#'",
    "#' Sends the text back.",
    "#'",
    "#' @param text Text to send back.",
    "#'",
    "#' @mcpTool",
    "#' @mcpType text type_string()",
    "#' @mcpReturns text",
    "echo <- function(text) {",
    "  text",
    "}"
  )
  dir.create(
    file.path(
      path,
      "R"
    ),
    showWarnings = FALSE
  )
  writeLines(
    tool,
    file.path(
      path,
      "R",
      "tool_echo.R"
    )
  )
  roxygen2::roclet_output(
    registry_roclet(),
    roxygen2::roc_proc_text(
      registry_roclet(),
      paste(
        tool,
        collapse = "\n"
      )
    ),
    base_path = path
  )
  local_install(
    path
  )
  requests <- withr::local_tempfile(
    lines = c(
      '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2025-11-25"}}',
      '{"jsonrpc":"2.0","method":"notifications/initialized"}',
      '{"jsonrpc":"2.0","id":2,"method":"tools/list"}',
      '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"echo","arguments":{"text":"trail"}}}'
    )
  )
  withr::local_envvar(
    R_LIBS = paste(
      .libPaths(),
      collapse = .Platform$path.sep
    )
  )

  responses <- lapply(
    system2(
      file.path(
        R.home(
          "bin"
        ),
        "Rscript"
      ),
      c(
        "--no-init-file",
        "-e",
        shQuote(
          "runlog::run_mcp_server()"
        )
      ),
      stdin = requests,
      stdout = TRUE,
      stderr = FALSE,
      timeout = 60
    ),
    jsonlite::fromJSON,
    simplifyVector = FALSE
  )

  expect_equal(
    vapply(
      responses,
      `[[`,
      numeric(1),
      "id"
    ),
    c(
      1,
      2,
      3
    )
  )
  expect_equal(
    responses[[1]]$result$serverInfo$name,
    "runlog"
  )
  expect_equal(
    responses[[2]]$result$tools[[1]]$name,
    "echo"
  )
  expect_equal(
    responses[[3]]$result$content[[1]]$text,
    "trail"
  )
})
