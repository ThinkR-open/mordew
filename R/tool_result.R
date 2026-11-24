tool_result <- function(
  value,
  returns,
  rows = NULL
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
        ),
        table = table_text(
          value,
          rows
        )
      )
    )
  )
}

table_text <- function(
  table,
  rows
) {
  shown <- utils::head(
    table,
    if (is.null(rows)) 50L else rows
  )
  lines <- c(
    paste(
      names(table),
      collapse = " | "
    ),
    paste(
      rep(
        "---",
        ncol(table)
      ),
      collapse = " | "
    ),
    do.call(
      paste,
      c(
        lapply(
          shown,
          markdown_cell
        ),
        sep = " | "
      )
    )
  )
  paste0(
    table_dimensions(
      table,
      shown
    ),
    "\n\n",
    paste0(
      "| ",
      lines,
      " |",
      collapse = "\n"
    )
  )
}

markdown_cell <- function(
  column
) {
  gsub(
    "|",
    "\\|",
    as.character(
      column
    ),
    fixed = TRUE
  )
}

table_dimensions <- function(
  table,
  shown
) {
  paste0(
    "Rows: ",
    nrow(table),
    if (nrow(shown) < nrow(table)) {
      paste0(
        " (first ",
        nrow(shown),
        " shown)"
      )
    },
    ". Columns: ",
    ncol(table),
    "."
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
      ),
    table = is.data.frame(
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
