# Run before deploying.

# Posit Connect: _server.yml makes {mordew} the engine that serves the package
mordew::add_connect()
rsconnect::deployAPI(
  ".",
  contentCategory = "mcp"
)
