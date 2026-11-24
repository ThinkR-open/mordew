start_server <- function(
  package,
  path = find.package(
    package
  ),
  timeout = 30
) {
  stdio_client(
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
        "); ",
        if (
          !dir.exists(
            file.path(
              path,
              "Meta"
            )
          )
        ) {
          paste0(
            "pkgload::load_all(",
            deparse(
              path
            ),
            ", quiet = TRUE); "
          )
        },
        package,
        "::run_mcp_server()"
      )
    ),
    timeout
  )
}

rscript <- function() {
  file.path(
    R.home(
      "bin"
    ),
    paste0(
      "Rscript",
      if (.Platform$OS.type == "windows") ".exe"
    )
  )
}

request_tool <- function(
  client,
  tool,
  args
) {
  response <- client_request(
    client,
    "tools/call",
    list(
      name = tool,
      arguments = if (length(args) == 0) empty_object() else args
    )
  )
  if (!is.null(response$error)) {
    stop(
      response$error$message,
      call. = FALSE
    )
  }
  response$result
}
