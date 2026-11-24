#' Add the Claude Code configuration file
#'
#' Writes the configuration file of [mcp_client_config()] for Claude Code at
#' the root of the package, as `<package>.json`, and adds it to
#' `.Rbuildignore`.
#'
#' @inheritParams mcp_client_config
#' @param overwrite Whether to replace an existing file.
#'
#' @export
add_mcp_client_config <- function(
  pkg = ".",
  overwrite = FALSE
) {
  package <- package_name(
    pkg
  )
  file <- file.path(
    pkg,
    paste0(
      package,
      ".json"
    )
  )
  if (
    file.exists(
      file
    ) &&
      !overwrite
  ) {
    stop(
      file,
      " already exists. Use `overwrite = TRUE` to replace it."
    )
  }
  writeLines(
    server_config(
      package
    ),
    file
  )
  buildignore <- file.path(
    pkg,
    ".Rbuildignore"
  )
  ignore <- paste0(
    "^",
    gsub(
      ".",
      "\\.",
      basename(
        file
      ),
      fixed = TRUE
    ),
    "$"
  )
  if (
    !ignore %in%
      readLines(
        buildignore
      )
  ) {
    cat(
      ignore,
      file = buildignore,
      sep = "\n",
      append = TRUE
    )
  }
}
