stream_tool_calls <- function(
  lines,
  package
) {
  blocks <- unlist(
    lapply(
      parse_stream(
        lines
      ),
      function(message) {
        message[["message"]][["content"]]
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

stream_result <- function(
  lines
) {
  unlist(
    lapply(
      parse_stream(
        lines
      ),
      function(message) {
        if (
          identical(
            message$type,
            "result"
          )
        ) {
          message$result
        }
      }
    )
  )
}

parse_stream <- function(
  lines
) {
  lapply(
    lines,
    jsonlite::fromJSON,
    simplifyVector = FALSE
  )
}
