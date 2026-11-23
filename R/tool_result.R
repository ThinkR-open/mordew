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
    !has_kind(
      value,
      returns
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
      switch(
        returns,
        text = value,
        json = as.character(
          jsonlite::toJSON(
            value,
            auto_unbox = TRUE,
            digits = NA,
            na = "null",
            null = "null"
          )
        )
      )
    )
  )
}

has_kind <- function(
  value,
  returns
) {
  switch(
    returns,
    text = is.character(
      value
    ),
    json = is.list(
      value
    ) &&
      !is.data.frame(
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
