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
    !grepl(
      "^[A-Za-z][A-Za-z0-9.]*[A-Za-z0-9]$",
      package_name
    )
  ) {
    stop(
      "`",
      package_name,
      "` is not a valid package name: it needs at least two letters, digits",
      " or dots, starting with a letter and not ending with a dot."
    )
  }
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
  files <- list.files(
    path,
    recursive = TRUE,
    full.names = TRUE
  )
  for (file in files) {
    fill_template(
      file,
      file,
      "mordewexample",
      package_name
    )
  }
}
