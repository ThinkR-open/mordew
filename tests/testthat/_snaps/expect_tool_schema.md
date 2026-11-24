# expect_tool_schema() snapshots the definition sent to clients

    Code
      cat(schema)
    Output
      {
          "name": "echo",
          "title": "Echo the text",
          "description": "Sends the text back.",
          "inputSchema": {
              "type": "object",
              "properties": {
                  "text": {
                      "type": "string",
                      "description": "Text to send back.\n"
                  }
              },
              "required": [
                  "text"
              ],
              "additionalProperties": false
          }
      }

