denied_functions <- c(
  "eval",
  "evalq",
  "parse",
  "str2lang",
  "str2expression",
  "source",
  "sys.source",
  "system",
  "system2",
  "shell"
)

denied_calls <- function(
  fun
) {
  intersect(
    called_functions(
      body(
        fun
      )
    ),
    denied_functions
  )
}

called_functions <- function(
  expr
) {
  if (!is.call(expr)) {
    return(
      character()
    )
  }
  c(
    function_name(
      expr[[1]]
    ),
    unlist(
      lapply(
        as.list(
          expr
        )[-1],
        called_functions
      )
    )
  )
}

function_name <- function(
  fn
) {
  if (
    is.call(
      fn
    ) &&
      is.symbol(
        fn[[1]]
      ) &&
      as.character(
        fn[[1]]
      ) %in%
        c(
          "::",
          ":::"
        )
  ) {
    fn <- fn[[3]]
  }
  if (
    is.symbol(
      fn
    )
  ) {
    as.character(
      fn
    )
  }
}
