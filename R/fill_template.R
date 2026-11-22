fill_template <- function(
  from,
  to,
  placeholder,
  value
) {
  dir.create(
    dirname(
      to
    ),
    recursive = TRUE,
    showWarnings = FALSE
  )
  writeLines(
    gsub(
      placeholder,
      value,
      readLines(
        from
      )
    ),
    to
  )
}
