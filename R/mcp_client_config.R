#' Configure an MCP client for the package
#'
#' Writes the most restricted configuration each client allows for the
#' package's MCP server, and says what the restriction leaves out. The server
#' runs with the full path of the current `Rscript`, which a desktop app may
#' not find on its `PATH`.
#'
#' @param client `"claude_code"` for a Claude Code session restricted to the
#'   server, `"claude_desktop"` for Claude Desktop.
#' @param pkg Path to the package.
#'
#' @return The configuration and its instructions, as lines of text.
#'
#' @export
mcp_client_config <- function(
  client = c(
    "claude_code",
    "claude_desktop"
  ),
  pkg = "."
) {
  client <- match.arg(
    client
  )
  package <- package_name(
    pkg
  )
  json <- server_config(
    package
  )
  structure(
    switch(
      client,
      claude_code = c(
        paste0(
          "Save as ",
          package,
          ".json:"
        ),
        json,
        "",
        "Start a Claude Code session restricted to the server:",
        paste0(
          'claude --tools "" --strict-mcp-config --mcp-config ',
          package,
          '.json --no-chrome --disallowedTools "mcp__ide" --allowedTools "mcp__',
          package,
          '__*" --permission-mode dontAsk --disable-slash-commands'
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
      ),
      claude_desktop = c(
        "Add to claude_desktop_config.json:",
        json,
        "",
        paste(
          "Claude Desktop keeps its other tools and connectors:",
          "this configuration only adds the server."
        )
      )
    ),
    class = "mordew_client_config"
  )
}

#' @export
print.mordew_client_config <- function(
  x,
  ...
) {
  cat(
    x,
    sep = "\n"
  )
  invisible(
    x
  )
}

server_config <- function(
  package
) {
  config <- list()
  config[[package]] <- list(
    command = rscript(),
    args = c(
      "--no-init-file",
      "-e",
      paste0(
        package,
        "::run_mcp_server()"
      )
    )
  )
  as.character(
    jsonlite::toJSON(
      list(
        mcpServers = config
      ),
      auto_unbox = TRUE,
      pretty = TRUE
    )
  )
}

package_name <- function(
  pkg
) {
  read.dcf(
    file.path(
      pkg,
      "DESCRIPTION"
    ),
    "Package"
  )[[1]]
}
