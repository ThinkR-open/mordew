#' Create a mordew package
#'
#' Copies the package template into `path` and names the package.
#'
#' @param path Directory to create.
#' @param package_name Name of the package.
#' @param overwrite Whether to delete and replace an existing `path`.
#'
#' @export
create_mordew <- function(
  path,
  package_name = basename(
    path
  ),
  overwrite = FALSE
) {
  if (
    dir.exists(
      path
    ) &&
      !overwrite
  ) {
    stop(
      path,
      " already exists. Use `overwrite = TRUE` to replace it."
    )
  }
  unlink(
    path,
    recursive = TRUE
  )
  dir.create(
    path,
    recursive = TRUE
  )
  template <- system.file(
    "mordewexample",
    package = "mordew"
  )
  file.copy(
    list.files(
      template,
      full.names = TRUE
    ),
    path,
    recursive = TRUE
  )
  file.rename(
    file.path(
      path,
      "REMOVEME.Rbuildignore"
    ),
    file.path(
      path,
      ".Rbuildignore"
    )
  )
  description <- file.path(
    path,
    "DESCRIPTION"
  )
  writeLines(
    gsub(
      "mordewexample",
      package_name,
      readLines(
        description
      )
    ),
    description
  )
}
