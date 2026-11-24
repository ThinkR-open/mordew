local_install <- function(
  path,
  env = parent.frame()
) {
  lib <- withr::local_tempfile(
    .local_envir = env
  )
  dir.create(
    lib
  )
  if (
    length(
      find.package(
        "mordew",
        lib.loc = .libPaths(),
        quiet = TRUE
      )
    ) ==
      0
  ) {
    install_source(
      test_path(
        "..",
        ".."
      ),
      lib
    )
  }
  install_source(
    path,
    lib
  )
  withr::local_libpaths(
    lib,
    action = "prefix",
    .local_envir = env
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
