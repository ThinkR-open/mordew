#' Add a tool
#'
#' Creates the tool file and its test file from templates.
#'
#' @param name Name of the tool.
#' @param pkg Path to the package.
#'
#' @export
add_tool <- function(
  name,
  pkg = "."
) {
  tool <- function_file(
    name,
    pkg,
    "tool"
  )
  fill_template(
    system.file(
      "templates",
      "tool.R",
      package = "mordew"
    ),
    tool,
    "mordewtool",
    name
  )
  fill_template(
    system.file(
      "templates",
      "test-tool.R",
      package = "mordew"
    ),
    file.path(
      pkg,
      "tests",
      "testthat",
      paste0(
        "test-tool_",
        name,
        ".R"
      )
    ),
    "mordewtool",
    name
  )
}
