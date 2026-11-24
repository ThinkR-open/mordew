#!/bin/sh
# Runs every scenario of the spike from the package root and prints the
# results: sh dev/spike_http/run.sh > dev/spike_http/spike.log 2>&1
measure() {
  workers=$1; port=$2; shift 2
  Rscript --no-init-file dev/spike_http/server.R "$workers" "$port" 2> "/tmp/spike_http_$port.log" &
  server=$!
  until curl -s -o /dev/null -X POST "http://127.0.0.1:$port/mcp" -d '{"jsonrpc":"2.0","id":0,"method":"ping"}'; do sleep 0.2; done
  for scenario in "$@"; do
    echo "== $workers workers, $scenario"
    Rscript --no-init-file dev/spike_http/load.R "$port" "$scenario"
  done
  kill "$server"
  echo "-- server log, $workers workers"
  cat "/tmp/spike_http_$port.log"
}
measure 0 8100 four
measure 4 8101 four eight twelve
measure 1 8102 timeout
