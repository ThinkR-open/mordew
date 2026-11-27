function_file <- function(
  name,
  pkg,
  kind
) {
  if (
    make.names(
      name
    ) !=
      name
  ) {
    stop(
      "`",
      name,
      "` is not a syntactic name: it becomes the name of the ",
      kind,
      "'s function."
    )
  }
  path <- file.path(
    pkg,
    "R",
    paste0(
      kind,
      "_",
      name,
      ".R"
    )
  )
  if (
    file.exists(
      path
    )
  ) {
    stop(
      path,
      " already exists."
    )
  }
  path
}
