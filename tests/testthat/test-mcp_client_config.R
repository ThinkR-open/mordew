local_runlog <- function(
  env = parent.frame()
) {
  path <- file.path(
    withr::local_tempfile(
      .local_envir = env
    ),
    "runlog"
  )
  create_mordew(
    path
  )
  path
}

server_json <- function() {
  paste0(
    '{\n  "mcpServers": {\n    "runlog": {\n      "command": ',
    jsonlite::toJSON(
      rscript(),
      auto_unbox = TRUE
    ),
    ',\n      "args": ["--no-init-file", "-e", "runlog::run_mcp_server()"]',
    "\n    }\n  }\n}"
  )
}

test_that("mcp_client_config() writes the Claude Desktop configuration", {
  expect_equal(
    unclass(
      mcp_client_config(
        "claude_desktop",
        pkg = local_runlog()
      )
    ),
    c(
      "Add to claude_desktop_config.json:",
      server_json(),
      "",
      paste(
        "Claude Desktop keeps its other tools and connectors:",
        "this configuration only adds the server."
      )
    )
  )
})

test_that("mcp_client_config() writes a Claude Code session restricted to the server", {
  expect_equal(
    unclass(
      mcp_client_config(
        "claude_code",
        pkg = local_runlog()
      )
    ),
    c(
      "Save as runlog.json:",
      server_json(),
      "",
      "Start a Claude Code session restricted to the server:",
      paste(
        'claude --tools "" --strict-mcp-config --mcp-config runlog.json',
        '--allowedTools "mcp__runlog__*" --disable-slash-commands'
      ),
      "",
      paste(
        "The session has no built-in tools, skills or other MCP servers.",
        "Claude Code refuses --strict-mcp-config when an organisation",
        "deploys a managed-mcp.json."
      )
    )
  )
})

test_that("mcp_client_config() prints the configuration as text", {
  expect_output(
    print(
      mcp_client_config(
        "claude_desktop",
        pkg = local_runlog()
      )
    ),
    "Add to claude_desktop_config.json:\n{",
    fixed = TRUE
  )
})

test_that("rscript() points to the Rscript of the running R", {
  expect_true(
    file.exists(
      rscript()
    )
  )
})
