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
        '--no-chrome --disallowedTools "mcp__ide"',
        '--allowedTools "mcp__runlog__*" --permission-mode dontAsk',
        "--disable-slash-commands"
      ),
      "",
      paste(
        "The session has no skills, no other MCP servers and no built-in",
        "tools apart from EndConversation, which only ends the conversation.",
        "Claude Code refuses --strict-mcp-config when an organisation",
        "deploys a managed-mcp.json."
      ),
      "",
      paste(
        "--disable-slash-commands also removes /mcp: to see the server's",
        "status, run the command without it."
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

test_that("mcp_client_config() allows the tools of a package with a dot in its name", {
  path <- file.path(
    withr::local_tempfile(),
    "run.log"
  )
  create_mordew(
    path
  )

  expect_match(
    mcp_client_config(
      "claude_code",
      pkg = path
    )[[5]],
    '--allowedTools "mcp__run_log__*"',
    fixed = TRUE
  )
})
