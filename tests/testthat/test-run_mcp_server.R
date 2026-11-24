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
  skip_if_not_installed(
    "processx"
  )
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
