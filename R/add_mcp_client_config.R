#' Add the Claude Code configuration file
#'
#' Writes the configuration file of [mcp_client_config()] for Claude Code at
#' the root of the package, as `<package>.json`, and adds it to
#' `.Rbuildignore` and `.gitignore`: it holds the path of the current
#' `Rscript`, which differs from one machine to the next.
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
  add_line(
    file.path(
      pkg,
      ".Rbuildignore"
    ),
    paste0(
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
  )
  add_line(
    file.path(
      pkg,
      ".gitignore"
    ),
    paste0(
      "/",
      basename(
        file
      )
    )
  )
}

add_line <- function(
  file,
  line
) {
  if (
    !file.exists(
      file
    ) ||
      !line %in%
        readLines(
          file
        )
  ) {
    cat(
      line,
      file = file,
      sep = "\n",
      append = TRUE
    )
  }
}
