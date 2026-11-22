# Spike: a minimal MCP stdio server in base R + jsonlite.
# Scope: initialize, ping, tools/list, tools/call, one hard-coded tool.
# Run with: Rscript --no-init-file server.R
# (--no-init-file: a .Rprofile that prints to stdout corrupts the JSON-RPC stream)

suppressPackageStartupMessages(library(jsonlite))

EMPTY_OBJ <- structure(list(), names = character(0))

spike_log <- function(...) {
  msg <- paste0(format(Sys.time(), "%H:%M:%S"), " ", ...)
  cat(msg, "\n", file = stderr())
  log_file <- Sys.getenv("SPIKE_LOG")
  if (nzchar(log_file)) cat(msg, "\n", file = log_file, append = TRUE)
}

send <- function(x) {
  cat(toJSON(x, auto_unbox = TRUE, null = "null"), "\n", sep = "")
  flush(stdout())
}

reply <- function(id, result) {
  send(list(jsonrpc = "2.0", id = id, result = result))
}

reply_error <- function(id, code, message) {
  send(list(
    jsonrpc = "2.0",
    id = id,
    error = list(code = code, message = message)
  ))
}

TOOLS <- list(
  list(
    name = "summarise_runs",
    description = paste(
      "Summarise runs for one surface and one year:",
      "number of runs, total distance (km), elevation gain (m),",
      "average pace (min/km).",
      "Use it for questions about training volume over a year."
    ),
    inputSchema = list(
      type = "object",
      properties = list(
        surface = list(type = "string", enum = c("road", "trail", "track")),
        year = list(type = "integer", description = "Four-digit year")
      ),
      required = c("surface", "year")
    )
  )
)

summarise_runs <- function(surface, year) {
  if (!surface %in% c("road", "trail", "track")) {
    stop("surface must be road, trail or track")
  }
  year <- as.integer(year)
  set.seed(year + nchar(surface) * 1000L)
  n <- sample(20:80, 1)
  km <- round(runif(1, 8, 15) * n)
  dplus <- round(km * if (surface == "trail") 25 else 8)
  pace <- round(runif(1, 4.5, 6.5), 1)
  sprintf(
    "%d %s runs in %d: %d km, %d m of elevation gain, average pace %.1f min/km.",
    n,
    surface,
    year,
    km,
    dplus,
    pace
  )
}

handle <- function(msg) {
  id <- msg$id
  method <- msg$method
  if (is.null(method)) {
    return(invisible(NULL)) # a response, not a request
  }
  spike_log(if (is.null(id)) "notification: " else "request: ", method)
  if (is.null(id)) {
    return(invisible(NULL)) # notifications get no response
  }
  if (method == "initialize") {
    spike_log("protocolVersion: ", msg$params$protocolVersion)
    reply(
      id,
      list(
        protocolVersion = msg$params$protocolVersion, # spike: echo, no negotiation
        capabilities = list(tools = EMPTY_OBJ),
        serverInfo = list(name = "runlog-spike", version = "0.0.1")
      )
    )
  } else if (method == "ping") {
    reply(id, EMPTY_OBJ)
  } else if (method == "tools/list") {
    reply(id, list(tools = TOOLS))
  } else if (method == "tools/call") {
    if (!identical(msg$params$name, "summarise_runs")) {
      return(reply_error(id, -32602, paste0("Unknown tool: ", msg$params$name)))
    }
    result <- tryCatch(
      list(
        content = list(list(
          type = "text",
          text = do.call(summarise_runs, msg$params$arguments)
        )),
        isError = FALSE
      ),
      error = function(e) {
        list(
          content = list(list(type = "text", text = conditionMessage(e))),
          isError = TRUE
        )
      }
    )
    reply(id, result)
  } else {
    reply_error(id, -32601, paste0("Method not found: ", method))
  }
}

stdin <- file("stdin", open = "r", blocking = TRUE)
spike_log("server started, pid ", Sys.getpid())
repeat {
  line <- readLines(stdin, n = 1, warn = FALSE)
  if (length(line) == 0) {
    break
  } # EOF: client is gone
  if (!nzchar(trimws(line))) {
    next
  }
  msg <- tryCatch(
    fromJSON(line, simplifyVector = FALSE),
    error = function(e) NULL
  )
  if (is.null(msg)) {
    reply_error(NULL, -32700, "Parse error")
    next
  }
  handle(msg)
}
spike_log("stdin closed, exiting")
