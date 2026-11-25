local_fake_claude <- function(
  record,
  env = parent.frame()
) {
  bin <- withr::local_tempfile(
    .local_envir = env
  )
  dir.create(
    bin
  )
  claude <- file.path(
    bin,
    "claude"
  )
  writeLines(
    c(
      "#!/bin/sh",
      paste(
        "printf '%s\\n' \"$@\" >",
        shQuote(
          file.path(
            record,
            "args"
          )
        )
      ),
      paste(
        "cp runlog.json",
        shQuote(
          file.path(
            record,
            "config.json"
          )
        )
      ),
      paste(
        "cat",
        shQuote(
          normalizePath(
            test_path(
              "fixtures",
              "claude-stream.jsonl"
            )
          )
        )
      )
    ),
    claude
  )
  Sys.chmod(
    claude,
    "755"
  )
  withr::local_path(
    bin,
    action = "prefix",
    .local_envir = env
  )
}
