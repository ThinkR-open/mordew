tool_result <- function(
  value,
  returns
) {
  if (
    inherits(
      value,
      "error"
    )
  ) {
    return(
      error_result(
        conditionMessage(
          value
        )
      )
    )
  }
  if (
    !is.character(
      value
    )
  ) {
    return(
      error_result(
        paste0(
          "The tool declares @mcpReturns ",
          returns,
          ", but returned class ",
          class(value)[[1]],
          "."
        )
      )
    )
  }
  list(
    content = text_content(
      value
    )
  )
}

error_result <- function(
  message
) {
  list(
    content = text_content(
      message
    ),
    isError = TRUE
  )
}

text_content <- function(
  text
) {
  list(
    list(
      type = "text",
      text = text
    )
  )
}
