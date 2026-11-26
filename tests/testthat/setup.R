withr::local_envvar(
  TMPDIR = withr::local_tempdir(
    .local_envir = teardown_env()
  ),
  .local_envir = teardown_env()
)
