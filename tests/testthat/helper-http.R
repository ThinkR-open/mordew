rook_request <- function(
  body = '{"jsonrpc":"2.0","id":1,"method":"ping"}',
  method = "POST",
  headers = c(
    "content-type" = "application/json"
  )
) {
  list(
    REQUEST_METHOD = method,
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
  headers = list()
) {
  list(
    method = method,
    headers = headers,
    body = body
  )
}
