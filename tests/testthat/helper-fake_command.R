local_fake_command <- function(
  name,
  lines,
  env = parent.frame()
) {
  bin <- withr::local_tempfile(
    .local_envir = env
  )
  dir.create(
    bin
  )
  command <- file.path(
    bin,
    name
  )
  writeLines(
    c(
      "#!/bin/sh",
      lines
    ),
    command
  )
  Sys.chmod(
    command,
    "755"
  )
  withr::local_path(
    bin,
    action = "prefix",
    .local_envir = env
  )
}

record_args <- function(
  record
) {
  paste(
    "printf '%s\\n' \"$@\" >",
    shQuote(
      file.path(
        record,
        "args"
      )
    )
  )
}

print_fixture <- function(
  fixture
) {
  if (!is.null(fixture)) {
    paste(
      "cat",
      shQuote(
        normalizePath(
          test_path(
            "fixtures",
            fixture
          )
        )
      )
    )
  }
}

print_stderr <- function(
  stderr
) {
  if (!is.null(stderr)) {
    paste(
      "echo",
      shQuote(
        stderr
      ),
      ">&2"
    )
  }
}

local_fake_claude <- function(
  record,
  stream = "claude-stream.jsonl",
  stderr = NULL,
  status = 0,
  env = parent.frame()
) {
  local_fake_command(
    "claude",
    c(
      record_args(
        record
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
      print_fixture(
        stream
      ),
      print_stderr(
        stderr
      ),
      paste(
        "exit",
        status
      )
    ),
    env
  )
}

local_fake_npx <- function(
  record,
  output = "inspector-call.json",
  stderr = NULL,
  status = 0,
  env = parent.frame()
) {
  local_fake_command(
    "npx",
    c(
      record_args(
        record
      ),
      print_fixture(
        output
      ),
      print_stderr(
        stderr
      ),
      paste(
        "exit",
        status
      )
    ),
    env
  )
}
