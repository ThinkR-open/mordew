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

wait_for <- function(
  promise
) {
  value <- NULL
  promises::then(
    promise,
    onFulfilled = function(result) {
      value <<- result
    },
    onRejected = function(error) {
      value <<- error
    }
  )
  deadline <- Sys.time() + 30
  while (is.null(value) && Sys.time() < deadline) {
    later::run_now(
      0.1
    )
  }
  value
}
