test_that("stream_tool_calls() reads the tool calls of a Claude Code stream", {
  expect_identical(
    stream_tool_calls(
      readLines(
        test_path(
          "fixtures",
          "claude-stream.jsonl"
        ),
        encoding = "UTF-8"
      ),
      "runlog"
    ),
    list(
      tool_call(
        "fastest_runs",
        n = 3L,
        type = "interval"
      )
    )
  )
})
