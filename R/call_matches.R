call_matches <- function(
  expected,
  actual
) {
  identical(
    expected$tool,
    actual$tool
  ) &&
    setequal(
      names(
        expected$args
      ),
      names(
        actual$args
      )
    ) &&
    all(
      vapply(
        names(
          expected$args
        ),
        function(name) {
          arg_matches(
            expected$args[[name]],
            actual$args[[name]]
          )
        },
        logical(
          1
        )
      )
    )
}

arg_matches <- function(
  expected,
  actual
) {
  if (
    inherits(
      expected,
      "partial"
    )
  ) {
    return(
      nzchar(
        actual
      ) &&
        grepl(
          tolower(
            actual
          ),
          tolower(
            expected
          ),
          fixed = TRUE
        )
    )
  }
  identical(
    as.character(
      expected
    ),
    as.character(
      actual
    )
  )
}
