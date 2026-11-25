extreme_values <- function(
  schema
) {
  candidates <- switch(
    schema$type,
    string = if (is.null(schema$enum)) {
      list(
        "",
        strrep(
          "a",
          1e5
        )
      )
    },
    integer = list(
      schema$minimum,
      schema$maximum,
      .Machine$integer.max,
      -.Machine$integer.max
    ),
    number = list(
      schema$minimum,
      schema$maximum,
      .Machine$double.xmax,
      -.Machine$double.xmax
    )
  )
  Filter(
    function(value) {
      !is.null(
        value
      ) &&
        is.null(
          argument_problem(
            value,
            schema
          )
        )
    },
    candidates
  )
}
