#' Expect a tool definition to match its snapshot
#'
#' Snapshots the tool definition as `tools/list` sends it to clients: name,
#' title, description, input schema and annotations. Any change to the tool's
#' interface then shows up in review.
#'
#' @inheritParams call_tool
#'
#' @export
expect_tool_schema <- function(
  tool,
  package = testthat::testing_package()
) {
  schema <- jsonlite::prettify(
    json_line(
      tool_definition(
        tool,
        package
      )
    )
  )
  testthat::expect_snapshot(
    cat(
      schema
    )
  )
}

tool_definition <- function(
  tool,
  package
) {
  definition <- asNamespace(
    package
  )$mordew_registry[[tool]]$tool
  if (is.null(definition)) {
    stop(
      "`",
      package,
      "` has no tool named `",
      tool,
      "`.",
      call. = FALSE
    )
  }
  definition
}
