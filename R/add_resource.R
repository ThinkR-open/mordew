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
  package <- package_name(
    pkg
  )
  fill_names(
    "resource.R",
    resource,
    "mordewresource",
    name,
    package
  )
  fill_names(
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
    "mordewresource",
    name,
    package
  )
}

fill_names <- function(
  template,
  to,
  placeholder,
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
    placeholder,
    name
  )
  fill_template(
    to,
    to,
    "mordewexample",
    package
  )
}
