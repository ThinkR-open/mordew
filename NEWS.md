# mordew 0.0.0.9023

* A `text` result sends a character vector as one string, one element per
  line: MCP takes a single string (#1).
* `run_mcp_server(token = NULL)` serves without a token, as `token = ""`
  does (#8).
* `expect_hostile_safe()` stops on a tool the package does not have, as
  `expect_tool_schema()` does, instead of passing without a call (#7).

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
