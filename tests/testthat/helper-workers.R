local_workers <- function(
  workers,
  package,
  env = parent.frame()
) {
  withr::local_envvar(
    R_LIBS = Sys.getenv(
      "R_LIBS",
      NA
    ),
    .local_envir = env
  )
  start_workers(
    workers,
    package
  )
  withr::defer(
    mirai::daemons(
      0
    ),
    envir = env
  )
}
