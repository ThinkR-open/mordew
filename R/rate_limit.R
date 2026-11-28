rate_limits <- function(
  completions,
  tool_calls
) {
  list(
    "completion/complete" = new_rate_limit(
      completions,
      "Too many completion requests: retry later."
    ),
    "tools/call" = new_rate_limit(
      tool_calls,
      "Too many tool calls: retry later."
    )
  )
}

new_rate_limit <- function(
  per_second,
  refusal
) {
  limit <- new.env(
    parent = emptyenv()
  )
  limit$per_second <- per_second
  limit$refusal <- refusal
  limit$times <- numeric()
  limit
}

limited_response <- function(
  message,
  limits
) {
  if (!is.list(message) || !is.character(message[["method"]])) {
    return(
      NULL
    )
  }
  limit <- limits[[message[["method"]]]]
  if (is.null(limit)) {
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
        limit$refusal
      )
    )
  }
  limit$times <- c(
    limit$times,
    now
  )
  NULL
}
