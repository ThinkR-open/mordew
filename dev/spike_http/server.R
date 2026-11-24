# Spike: an asynchronous MCP front over HTTP, tools in mirai workers
# (architecture B). It reuses mordew's handle_message(), in the front for
# initialize, ping and tools/list, and in a worker for tools/call.
# Run from the package root:
#   Rscript --no-init-file dev/spike_http/server.R <workers> <port>
# workers = 0 runs tools in the front itself, as a synchronous server does.
# Scope: POST with a JSON response, 202 for notifications, 405 otherwise; no
# session, no SSE, no Origin check, no MCP-Protocol-Version check.

pkgload::load_all(quiet = TRUE)
args <- as.integer(commandArgs(trailingOnly = TRUE))
workers <- args[[1]]
port <- args[[2]]
timeout_ms <- 3000
limit <- 2 * max(workers, 1)

slow_echo <- function(text, seconds) {
  Sys.sleep(seconds)
  text
}
registry <- list(
  slow_echo = list(
    fun = "slow_echo",
    tool = list(
      name = "slow_echo",
      description = "Wait, then send the text back.",
      inputSchema = type_object(
        text = type_string(),
        seconds = type_number(min = 0)
      )$schema
    ),
    returns = "text"
  )
)
server <- list(name = "spike", version = "0.0.1", instructions = "Spike.")
tools <- new.env()
tools$slow_echo <- slow_echo

if (workers > 0) {
  mirai::daemons(workers, dispatcher = TRUE)
  invisible(mirai::everywhere(
    pkgload::load_all(path, quiet = TRUE),
    path = getwd()
  )[])
}

in_flight <- 0
log_line <- function(...) {
  cat(format(Sys.time(), "%H:%M:%OS3"), ..., "\n", file = stderr())
}

json_response <- function(x) {
  list(
    status = 200L,
    headers = list("Content-Type" = "application/json"),
    body = as.character(json_line(x))
  )
}

call_in_worker <- function(message) {
  in_flight <<- in_flight + 1
  started <- Sys.time()
  m <- mirai::mirai(
    {
      started <- Sys.time()
      list(
        response = mordew:::handle_message(message, server, registry, tools),
        started = started,
        pid = Sys.getpid()
      )
    },
    message = message,
    server = server,
    registry = registry,
    tools = tools,
    .timeout = timeout_ms
  )
  promises::finally(
    promises::then(
      m,
      onFulfilled = function(value) {
        log_line(
          "tools/call",
          message$id,
          "worker",
          value$pid,
          "queued",
          round(as.numeric(value$started - started, units = "secs"), 2),
          "s,",
          "ran",
          round(as.numeric(Sys.time() - value$started, units = "secs"), 2),
          "s"
        )
        json_response(value$response)
      },
      onRejected = function(error) {
        log_line(
          "tools/call",
          message$id,
          conditionMessage(error),
          "after",
          round(as.numeric(Sys.time() - started, units = "secs"), 2),
          "s"
        )
        pool <- mirai::info()
        log_line(
          "pool:",
          paste(names(pool), pool, collapse = ", ")
        )
        json_response(rpc_response(
          message$id,
          list(
            result = list(
              content = list(list(
                type = "text",
                text = paste0(
                  "The tool did not finish within ",
                  timeout_ms / 1000,
                  " seconds."
                )
              )),
              isError = TRUE
            )
          )
        ))
      }
    ),
    onFinally = function() {
      in_flight <<- in_flight - 1
    }
  )
}

app <- list(
  call = function(req) {
    if (req$REQUEST_METHOD != "POST") {
      return(list(status = 405L, headers = list(Allow = "POST"), body = ""))
    }
    message <- tryCatch(
      jsonlite::fromJSON(
        rawToChar(req$rook.input$read()),
        simplifyVector = FALSE
      ),
      error = identity
    )
    if (inherits(message, "error")) {
      return(json_response(rpc_response(
        NULL,
        rpc_error(-32700, "Parse error")
      )))
    }
    if (is.null(message$id)) {
      return(list(status = 202L, headers = list(), body = ""))
    }
    log_line("received", message$method, message$id)
    if (workers > 0 && identical(message$method, "tools/call")) {
      if (in_flight >= limit) {
        log_line("tools/call", message$id, "refused: busy")
        return(json_response(rpc_response(
          message$id,
          list(
            result = list(
              content = list(list(
                type = "text",
                text = "The server is busy: retry later."
              )),
              isError = TRUE
            )
          )
        )))
      }
      return(call_in_worker(message))
    }
    json_response(handle_message(message, server, registry, tools))
  }
)

log_line("spike server on port", port, "with", workers, "workers")
httpuv::runServer("127.0.0.1", port, app)
