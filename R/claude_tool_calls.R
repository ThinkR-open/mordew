claude_tool_calls <- function(
  question,
  pkg = "."
) {
  package <- package_name(
    pkg
  )
  session <- tempfile()
  dir.create(
    session
  )
  on.exit(
    unlink(
      session,
      recursive = TRUE
    )
  )
  writeLines(
    server_config(
      package,
      server_args(
        package,
        normalizePath(
          pkg
        )
      )
    ),
    file.path(
      session,
      paste0(
        package,
        ".json"
      )
    )
  )
  run <- processx::run(
    "claude",
    c(
      "-p",
      question,
      "--output-format",
      "stream-json",
      "--verbose",
      claude_args(
        package
      )
    ),
    wd = session,
    error_on_status = FALSE
  )
  lines <- strsplit(
    run$stdout,
    "\n"
  )[[1]]
  if (run$status != 0) {
    stop(
      "claude failed: ",
      run$stderr,
      stream_result(
        lines
      ),
      call. = FALSE
    )
  }
  stream_tool_calls(
    lines,
    package
  )
}
