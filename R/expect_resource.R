#' Expect a resource to be read through an MCP client
#'
#' Reads the resource with [read_resource()], and expects its text to match
#' `regexp`. A resource that cannot be read, an unknown URI or a function
#' that fails, is an error.
#'
#' @inheritParams read_resource
#' @param regexp Regular expression the text of the resource must match, or
#'   `NULL`.
#' @param ... Passed to [read_resource()].
#'
#' @return The result of `resources/read`, invisibly.
#'
#' @export
expect_resource <- function(
  uri,
  regexp = NULL,
  ...
) {
  result <- read_resource(
    uri,
    ...
  )
  text <- result$contents[[1]]$text
  testthat::expect(
    is.null(
      regexp
    ) ||
      grepl(
        regexp,
        text
      ),
    paste0(
      "The text of resource `",
      uri,
      "` does not match `",
      regexp,
      "`:\n",
      text
    )
  )
  invisible(
    result
  )
}
