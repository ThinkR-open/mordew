#' Add the Posit Connect file
#'
#' Writes `_server.yml` at the root of the package, with `engine: mordew`,
#' and keeps it out of the build. Posit Connect then serves the package over
#' HTTP through `{mordew}`, following plumber2's `_server.yml` standard:
#' deploy with `rsconnect::deployAPI(".", contentCategory = "mcp")`.
#' Connect authenticates the clients itself, with its API keys.
#'
#' @param pkg Path to the package.
#'
#' @export
add_connect <- function(
  pkg = "."
) {
  writeLines(
    "engine: mordew",
    file.path(
      pkg,
      "_server.yml"
    )
  )
  add_line(
    file.path(
      pkg,
      ".Rbuildignore"
    ),
    "^_server\\.yml$"
  )
}

launch_server <- function(
  settings,
  host = NULL,
  port = NULL,
  ...
) {
  if (
    !identical(
      trimws(
        readLines(
          settings,
          n = 1,
          warn = FALSE
        )
      ),
      "engine: mordew"
    )
  ) {
    stop(
      settings,
      " must start with `engine: mordew`.",
      call. = FALSE
    )
  }
  path <- dirname(
    settings
  )
  lib <- file.path(
    tempdir(),
    "mordew-connect"
  )
  dir.create(
    lib,
    showWarnings = FALSE
  )
  .libPaths(
    c(
      lib,
      .libPaths()
    )
  )
  utils::install.packages(
    path,
    repos = NULL,
    type = "source",
    lib = lib,
    quiet = TRUE
  )
  serve_http(
    if (is.null(host)) "127.0.0.1" else host,
    if (is.null(port)) 8000 else port,
    package_name(
      path
    ),
    4,
    60,
    8,
    NULL
  )
}
