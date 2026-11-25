rook_request <- function(
  body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
  method = "POST",
  headers = c(
    "content-type" = "application/json"
  ),
  path = "/mcp"
) {
  list(
    REQUEST_METHOD = method,
    PATH_INFO = path,
    HEADERS = headers,
    rook.input = list(
      read = function() {
        charToRaw(
          body
        )
      }
    )
  )
}

http_request <- function(
  body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
  method = "POST",
  headers = list(),
  path = "/mcp"
) {
  list(
    method = method,
    path = path,
    headers = headers,
    body = body
  )
}
