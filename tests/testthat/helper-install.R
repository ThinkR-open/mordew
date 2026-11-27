local_mordew_lib <- function(
  env = parent.frame()
) {
  lib <- withr::local_tempfile(
    .local_envir = env
  )
  dir.create(
    lib
  )
  withr::local_libpaths(
    c(
      lib,
      mordew_lib()
    ),
    action = "prefix",
    .local_envir = env
  )
  lib
}

mordew_lib <- function() {
  lib <- file.path(
    tempdir(),
    "mordew-lib"
  )
  if (
    !dir.exists(
      lib
    )
  ) {
    dir.create(
      lib
    )
    installed <- tryCatch(
      utils::packageVersion(
        "mordew",
        lib.loc = .libPaths()
      ),
      error = function(error) {
        NULL
      }
    )
    if (
      !identical(
        installed,
        utils::packageVersion(
          "mordew"
        )
      )
    ) {
      install_source(
        test_path(
          "..",
          ".."
        ),
        lib
      )
    }
  }
  lib
}

local_install <- function(
  path,
  env = parent.frame()
) {
  install_source(
    path,
    local_mordew_lib(
      env
    )
  )
}

install_source <- function(
  path,
  lib
) {
  utils::install.packages(
    path,
    repos = NULL,
    type = "source",
    lib = lib,
    quiet = TRUE
  )
}

local_tool_package <- function(
  env = parent.frame(),
  tools = c(
    "#' Echo the text",
    "#'",
    "#' Sends the text back.",
    "#'",
    "#' @param text Text to send back.",
    "#'",
    "#' @mcpTool",
    "#' @mcpType text type_string()",
    "#' @mcpReturns text",
    "echo <- function(text) {",
    "  text",
    "}",
    "",
    "#' Fail",
    "#'",
    "#' Always fails.",
    "#'",
    "#' @mcpTool",
    "#' @mcpReturns text",
    "fail_always <- function() {",
    "  stop(\"No runs today.\")",
    "}",
    "",
    "#' Surfaces",
    "#'",
    "#' The surfaces a run can be on.",
    "#'",
    "#' @mcpResource runlog://surfaces",
    "surfaces <- function() {",
    "  \"road, trail, track\"",
    "}"
  )
) {
  path <- file.path(
    withr::local_tempfile(
      .local_envir = env
    ),
    "runlog"
  )
  create_mordew(
    path
  )
  writeLines(
    tools,
    file.path(
      path,
      "R",
      "tools.R"
    )
  )
  roxygen2::roclet_output(
    registry_roclet(),
    roxygen2::roc_proc_text(
      registry_roclet(),
      paste(
        tools,
        collapse = "\n"
      )
    ),
    base_path = path
  )
  path
}

local_dev_package <- function(
  path = local_tool_package(
    env
  ),
  env = parent.frame()
) {
  local_mordew_lib(
    env
  )
  pkgload::load_all(
    path,
    quiet = TRUE
  )
  withr::defer(
    pkgload::unload(
      "runlog"
    ),
    envir = env
  )
  path
}
