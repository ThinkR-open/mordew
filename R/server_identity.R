server_identity <- function(
  package
) {
  list(
    name = package,
    version = utils::packageDescription(
      package,
      fields = "Version"
    ),
    instructions = paste(
      readLines(
        system.file(
          "mordew",
          "instructions.md",
          package = package
        )
      ),
      collapse = "\n"
    )
  )
}
