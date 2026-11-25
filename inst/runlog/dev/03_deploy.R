# Run before deploying.

# Docker: a Dockerfile that serves the package over HTTP
mordew::add_dockerfile()

# Posit Connect: _server.yml makes {mordew} the engine that serves the package
mordew::add_connect()
rsconnect::deployAPI(
  ".",
  contentCategory = "mcp"
)
