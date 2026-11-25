stream_tool_calls <- function(
  lines,
  package
) {
  blocks <- unlist(
    lapply(
      lines,
      function(line) {
        jsonlite::fromJSON(
          line,
          simplifyVector = FALSE
        )[["message"]][["content"]]
      }
    ),
    recursive = FALSE
  )
  lapply(
    Filter(
      function(block) {
        identical(
          block$type,
          "tool_use"
        )
      },
      blocks
    ),
    function(block) {
      list(
        tool = sub(
          tool_prefix(
            package
          ),
          "",
          block$name,
          fixed = TRUE
        ),
        args = block$input
      )
    }
  )
}
