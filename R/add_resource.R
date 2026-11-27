#' Add a resource
#'
#' Creates the resource file and its test file from templates. Its URI is
#' `<package>://<name>`.
#'
#' @param name Name of the resource.
#' @param pkg Path to the package.
#'
#' @export
add_resource <- function(
  name,
  pkg = "."
) {
  resource <- function_file(
    name,
    pkg,
    "resource"
  )
  fill_template(
    system.file(
      "templates",
      "resource.R",
      package = "mordew"
    ),
    resource,
    "mordewresource",
    name
  )
  fill_template(
    resource,
    resource,
    "mordewexample",
    read.dcf(
      file.path(
        pkg,
        "DESCRIPTION"
      ),
      "Package"
    )[[1]]
  )
  fill_template(
    system.file(
      "templates",
      "test-resource.R",
      package = "mordew"
    ),
    file.path(
      pkg,
      "tests",
      "testthat",
      paste0(
        "test-resource_",
        name,
        ".R"
      )
    ),
    "mordewresource",
    name
  )
}
