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
