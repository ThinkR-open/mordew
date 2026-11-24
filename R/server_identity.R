server_identity <- function(
  package
) {
  instructions <- file.path(
    find.package(
      package
    ),
    c(
      "mordew",
      file.path(
        "inst",
        "mordew"
      )
    ),
    "instructions.md"
  )
  instructions <- instructions[file.exists(
    instructions
  )]
  if (length(instructions) == 0) {
    stop(
      "`",
      package,
      "` has no inst/mordew/instructions.md.",
      call. = FALSE
    )
  }
  list(
    name = package,
    version = utils::packageDescription(
      package,
      fields = "Version"
    ),
    instructions = paste(
      readLines(
        instructions[[1]]
      ),
      collapse = "\n"
    )
  )
}
