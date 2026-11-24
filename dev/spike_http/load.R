# Load test for the spike server:
#   Rscript --no-init-file dev/spike_http/load.R <port> <scenario>
# Sends the scenario's tool calls at once, adds a ping 0.2 seconds later,
# and prints when each response arrived, in seconds from the start.

args <- commandArgs(trailingOnly = TRUE)
url <- sprintf("http://127.0.0.1:%s/mcp", args[[1]])
scenario <- args[[2]]

request <- function(id, method, params = NULL) {
  message <- list(jsonrpc = "2.0", id = id, method = method)
  message$params <- params
  as.character(jsonlite::toJSON(message, auto_unbox = TRUE))
}

slow_call <- function(id, seconds) {
  request(
    id,
    "tools/call",
    list(
      name = "slow_echo",
      arguments = list(text = paste("call", id), seconds = seconds)
    )
  )
}

send <- function(bodies, later = list()) {
  pool <- curl::new_pool(total_con = 100, host_con = 100, multiplex = FALSE)
  start <- Sys.time()
  arrived <- list()
  add <- function(label, body) {
    force(label)
    handle <- curl::new_handle(url = url, post = TRUE, postfields = body)
    curl::handle_setheaders(
      handle,
      "Content-Type" = "application/json",
      Accept = "application/json, text/event-stream"
    )
    curl::multi_add(
      handle,
      done = function(response) {
        arrived[[label]] <<- data.frame(
          request = label,
          seconds = round(as.numeric(Sys.time() - start, units = "secs"), 2),
          answer = substr(
            jsonlite::fromJSON(rawToChar(
              response$content
            ))$result$content$text %||%
              "pong",
            1,
            45
          )
        )
      },
      pool = pool
    )
  }
  for (label in names(bodies)) {
    add(label, bodies[[label]])
  }
  curl::multi_run(timeout = 0.2, pool = pool)
  for (label in names(later)) {
    add(label, later[[label]])
  }
  curl::multi_run(pool = pool)
  result <- do.call(rbind, arrived)
  rownames(result) <- NULL
  result[order(result$seconds), ]
}

calls <- function(n, seconds) {
  stats::setNames(
    lapply(seq_len(n), slow_call, seconds = seconds),
    paste0("call_", seq_len(n))
  )
}
ping <- list(ping = request(100, "ping"))

print(switch(
  scenario,
  four = send(calls(4, 2), ping),
  eight = send(calls(8, 2), ping),
  twelve = send(calls(12, 2), ping),
  timeout = rbind(
    send(list(call_10s = slow_call(1, 10))),
    send(list(call_0.1s = slow_call(2, 0.1)))
  )
))
