new_rate_limit <- function(
  per_second
) {
  limit <- new.env(
    parent = emptyenv()
  )
  limit$per_second <- per_second
  limit$times <- numeric()
  limit
}

limited_response <- function(
  message,
  limit
) {
  if (
    is.null(limit) ||
      !is.list(message) ||
      !identical(
        message[["method"]],
        "completion/complete"
      )
  ) {
    return(
      NULL
    )
  }
  now <- as.numeric(
    Sys.time()
  )
  limit$times <- limit$times[limit$times > now - 1]
  if (length(limit$times) >= limit$per_second) {
    return(
      failure_response(
        message,
        "Too many completion requests: retry later."
      )
    )
  }
  limit$times <- c(
    limit$times,
    now
  )
  NULL
}
