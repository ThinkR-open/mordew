tool_result <- function(
  value,
  returns,
  rows = NULL,
  output = NULL
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
  content <- kind_content(
    value,
    returns,
    rows
  )
  if (is.null(output)) {
    return(
      list(
        content = content
      )
    )
  }
  structured <- jsonlite::fromJSON(
    content[[1]]$text,
    simplifyVector = FALSE
  )
  invalid <- tryCatch(
    validate_arguments(
      structured,
      output,
      "field"
    ),
    error = conditionMessage
  )
  if (is.character(invalid)) {
    return(
      error_result(
        paste0(
          "The tool returned a result that does not match its output schema: ",
          invalid
        )
      )
    )
  }
  list(
    content = content,
    structuredContent = structured
  )
}

kind_content <- function(
  value,
  returns,
  rows = NULL
) {
  switch(
    returns,
    text = text_content(
      paste(
        value,
        collapse = "\n"
      )
    ),
    json = text_content(
      as.character(
        jsonlite::toJSON(
          value,
          auto_unbox = TRUE,
          digits = NA,
          na = "null",
          null = "null"
        )
      )
    ),
    table = text_content(
      table_text(
        value,
        rows
      )
    ),
    image = image_content(
      value
    )
  )
}

image_content <- function(
  plot
) {
  file <- tempfile(
    fileext = ".png"
  )
  on.exit(
    unlink(
      file
    )
  )
  render_png(
    plot,
    file
  )
  list(
    list(
      type = "image",
      data = jsonlite::base64_enc(
        readBin(
          file,
          "raw",
          file.size(
            file
          )
        )
      ),
      mimeType = "image/png"
    )
  )
}

render_png <- function(
  plot,
  file
) {
  grDevices::png(
    file,
    width = 800,
    height = 600,
    res = 96
  )
  on.exit(
    grDevices::dev.off()
  )
  if (
    inherits(
      plot,
      "ggplot"
    )
  ) {
    print(
      plot
    )
  } else {
    grDevices::replayPlot(
      plot
    )
  }
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
      markdown_cell(
        names(table)
      ),
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
        unname(
          lapply(
            shown,
            markdown_cell
          )
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
    "\n",
    " ",
    gsub(
      "|",
      "\\|",
      as.character(
        column
      ),
      fixed = TRUE
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
    ),
    image = inherits(
      value,
      c(
        "ggplot",
        "recordedplot"
      )
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
      text = sanitize_text(
        text
      )
    )
  )
}

sanitize_text <- function(
  text
) {
  gsub(
    "[\\x01-\\x08\\x0B\\x0C\\x0E-\\x1F\\x7F]",
    "",
    gsub(
      "\\x1B\\[[0-9;?]*[ -/]*[@-~]",
      "",
      text,
      perl = TRUE
    ),
    perl = TRUE
  )
}
