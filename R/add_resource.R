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
  package <- read.dcf(
    file.path(
      pkg,
      "DESCRIPTION"
    ),
    "Package"
  )[[1]]
  fill_resource(
    "resource.R",
    resource,
    name,
    package
  )
  fill_resource(
    "test-resource.R",
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
    name,
    package
  )
}

fill_resource <- function(
  template,
  to,
  name,
  package
) {
  fill_template(
    system.file(
      "templates",
      template,
      package = "mordew"
    ),
    to,
    "mordewresource",
    name
  )
  fill_template(
    to,
    to,
    "mordewexample",
    package
  )
}
