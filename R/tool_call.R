#' Describe a tool call
#'
#' Describes a call the model is expected to make in an eval case.
#'
#' @param tool Name of the tool.
#' @param ... Arguments of the call, named. Wrap a value in [partial()] to
#'   accept part of it.
#'
#' @return A list with elements `tool` and `args`.
#'
#' @export
tool_call <- function(
  tool,
  ...
) {
  list(
    tool = tool,
    args = list(
      ...
    )
  )
}
