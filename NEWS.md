# mordew 0.0.0.9029

* `add_resource()` creates the file of a resource and its test file, with
  the URI `<package>://<name>`, as `add_tool()` does for a tool; the
  `dev/02_dev.R` of `create_mordew()` calls it.

# mordew 0.0.0.9028

* Resources: a function tagged `@mcpResource <uri>` becomes a resource that
  clients list with `resources/list` and read with `resources/read`, over
  stdio and HTTP. The registry roclet writes the resources in
  `mordew_resources`, next to `mordew_registry`, and stops on a resource
  without title or description, on an object that is not a function, and
  on two resources with the same URI. A resource is read as text, one
  element of the character vector per line; an unknown URI gets the error
  -32002, and a resource that fails or does not return text gets -32603.

# mordew 0.0.0.9027

* `add_dockerfile()` needs dockerfiler 1.0.1 or later, which computes the
  system requirements of a package listed in `Remotes`: the
  `dev/03_deploy.R` of `create_mordew()` no longer gives them by hand.

# mordew 0.0.0.9025

* Over HTTP, each tool call gives the workers the libraries of the server,
  `.libPaths()`: on Windows, they did not find a package installed in a
  library added with `.libPaths()`.

# mordew 0.0.0.9024

* Over HTTP, the worker pool also reads the method and the id of a message by
  their exact names, for the calls it sends to a worker and for its busy and
  timeout answers (#9).

# mordew 0.0.0.9023

* A `text` result sends a character vector as one string, one element per
  line: MCP takes a single string (#1).
* `run_mcp_server(token = NULL)` serves without a token, as `token = ""`
  does (#8).
* `expect_hostile_safe()` stops on a tool the package does not have, as
  `expect_tool_schema()` does, instead of passing without a call (#7).
* `add_mcp_client_config()` and `add_connect()` add their line to
  `.gitignore` and `.Rbuildignore` on a line of its own, also when the file
  does not end with a newline (#12).
* `create_mordew()` refuses a name that is not a valid package name, and
  `add_tool()` a name that is not syntactic, before writing anything (#13).
* The server reads the fields of a message, of its `params` and the HTTP
  headers by their exact names: a message with `idx` but no `id` stays a
  notification (#9).
* The registry roclet stops on a tool without title, which clients got as
  `"title": null`, and on `@mcpTool` on an object that is not a function
  (#14).
* The registry roclet writes non-ASCII characters as `\U{...}` escapes, so
  that a package documented in another language than English passes
  `R CMD check` (#4).
* Over HTTP, a path other than `/mcp` and `/health` gets a `404`, and
  another method than `GET` on `/health` a `405` (#10).
* Over HTTP, a request whose `Content-Length` is over 4 MB gets a `413` on
  its headers, before its body is read (#11).
* `add_dockerfile()` adds `^Dockerfile$` to `.Rbuildignore` (#5).
* The `DESCRIPTION` of a new package has `Remotes: ThinkR-open/mordew`, so
  that it installs `{mordew}` from GitHub until `{mordew}` is on CRAN (#6).
* The Dockerfile of `add_dockerfile()` starts the server with
  `mordew::run_mcp_server("<package>", ...)`, so that the container starts
  whatever arguments the package's own `run_mcp_server()` takes (#18).
* `add_dockerfile()` needs dockerfiler 1.0.0 or later, whose image build fails
  when a package does not install; with 0.2.5, the image lacked it (#19).
* `call_tool(client = "inspector")` runs `npx` without Node's compile cache,
  which left `node-compile-cache` in the temporary directory, and a note in
  `R CMD check` (#16).
* The `dev/03_deploy.R` of a new package checks the package with
  `devtools::check()`, then writes the Dockerfile with the system requirements
  given by hand, until dockerfiler computes them with `Remotes`.
* `call_tool(client = "inspector")` stops on Windows with a message that says
  it is not supported there yet, instead of "Command 'npx' not found" (#15).

* A `table` result escapes `|` in column names, and replaces newlines with
  spaces in column names and cells, so that the Markdown table keeps its
  columns and rows (#3).

# mordew 0.0.0.9022

* A `table` result keeps one row per row of the data frame when a column is
  named `sep`, `collapse` or `recycle0`, like an argument of `paste()` (#2).

# mordew 0.0.0.9018

* `{mordew}` requires the versions of its imports it is tested with: mirai
  2.5.1 did not load with the nanonext that an install from GitHub pulled.

# mordew 0.0.0.9017

* `expect_hostile_safe()` passes under testthat 3.3.

# mordew 0.0.0.9016

* Over HTTP, the origin, the token, the method and the protocol version are
  checked as soon as the headers arrive, before the body is read. `GET
  /health` is answered there too.

# mordew 0.0.0.9015

* `add_dockerfile()` writes a Dockerfile from dockerfiler's
  `dock_from_desc()`, with a non-root user, the port, a health check on
  `/health` and a start on `0.0.0.0`.
* `run_mcp_server()` serves on another host than localhost without a token,
  with a warning at start-up, so that a proxy or a gateway can authenticate
  the clients.
* A tool call whose `params` is a scalar, or whose `arguments` is an array or
  a string, gets a `-32602` invalid params error: the tool does not run.

# mordew 0.0.0.9014

* `add_connect()` writes `_server.yml` to serve the package on Posit Connect,
  which authenticates the clients. The `dev/03_deploy.R` of a new package
  deploys it with `rsconnect::deployAPI()`.
* Over HTTP:
  * a tool call that finds every worker busy waits in a bounded queue
    (`queue = 8`), and the timeout counts the run, not the wait;
  * a worker that stops during a tool call is replaced;
  * `GET /health` answers without a token;
  * with a token, from `MORDEW_TOKEN` by default, every other request must
    send `Authorization: Bearer <token>`, or gets a `401`.

# mordew 0.0.0.9013

* `run_mcp_server(transport = "http")` serves the tools over Streamable HTTP.
  Tool calls run in a pool of mirai workers (`workers`), at most one per
  worker, and stop after `timeout` seconds with an `isError` result.
* `call_tool(client = "inspector")` makes the call through the MCP Inspector
  CLI.
* `check_tools()` looks in the tools for calls that can turn an argument into
  code.
* `expect_hostile_safe()` calls a tool with the extreme values its schema
  accepts.
* `run_dev(client = "claude")` gives the command of a Claude Code session
  restricted to the development version of the package.
* With `ANTHROPIC_API_KEY` set, as in CI, the evals leave out the developer's
  `CLAUDE.md`, memory, hooks and plugins.

# mordew 0.0.0.9012

* Evals measure whether a model calls the right tool with the right
  arguments, through Claude Code:
  * `tool_call()` describes an expected call, and `partial()` accepts a value
    that is part of the expected one, ignoring case;
  * `eval_case()` describes a question and its accepted answers;
  * `run_evals()` runs the cases and flags a run that takes more calls than
    expected (`too_many_calls`);
  * `assert_pass_rate()` stops when a case fails too often;
  * `use_evals()` sets up `dev/evals.R` and a GitHub Actions workflow started
    by hand.
* When the claude CLI fails, the error shows its stderr and the result
  message of its stream.

# mordew 0.0.0.9006

* Tools of a package with a dot in its name are allowed in the restricted
  Claude Code session.
* `add_mcp_client_config()` adds the configuration file to `.gitignore`.
* The `dev/02_dev.R` of a new package calls `add_mcp_client_config()`.

# mordew 0.0.0.9005

* `add_mcp_client_config()` writes the Claude Code configuration file of the
  package.

# mordew 0.0.0.9003

* The restricted Claude Code session also leaves out the Claude in Chrome and
  IDE tools, and denies any call that would ask for permission.

# mordew 0.0.0.9000

* First version, implementing MCP 2025-11-25.
* `create_mordew()` creates an MCP server package, with its `dev/` scripts,
  and `add_tool()` adds a tool and its test. `install_dev_deps()` installs
  the development dependencies.
* `registry_roclet()` writes the tool registry to `R/mordew_registry.R` from
  roxygen: `@mcpTool`, `@mcpReturns`, `@mcpType` with `type_string()`,
  `type_integer()`, `type_number()`, `type_boolean()`, `type_enum()`,
  `type_array()` and `type_object()`, `@mcpLimit rows`, and the annotation
  tags `@mcpReadOnly`, `@mcpNonDestructive`, `@mcpIdempotent` and
  `@mcpClosedWorld`. `@mcpType` is checked against the function signature.
* Tool arguments are validated against the schema (unknown and missing
  arguments, types, enums, bounds, patterns, nested arrays and objects), then
  converted to R types.
* Tool results: `text`, `json`, `table` as a Markdown table, and `image` for
  a plot as an 800x600 PNG at 96 dpi. An error, or a value that does not
  match `@mcpReturns`, comes back as an `isError` result.
* `run_mcp_server()` serves the tools over stdio.
* `call_tool()`, `expect_tool_error()` and `expect_tool_schema()` test the
  tools with testthat through a stdio client.
* `run_dev()` chats with the development version through ellmer.
* `mcp_client_config()` gives the configuration of Claude Code and Claude
  Desktop.
