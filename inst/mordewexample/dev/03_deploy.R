# Run before deploying.

# Check the package
devtools::check()

# Docker: a Dockerfile that serves the package over HTTP. The system
# requirements are given by hand until dockerfiler computes them with
# Remotes: https://github.com/ThinkR-open/dockerfiler/issues/122
mordew::add_dockerfile(
  sysreqs = FALSE,
  extra_sysreqs = c(
    "cmake",
    "libuv1-dev",
    "make",
    "zlib1g-dev"
  )
)

# Posit Connect: _server.yml makes {mordew} the engine that serves the package
mordew::add_connect()
rsconnect::deployAPI(
  ".",
  contentCategory = "mcp"
)
