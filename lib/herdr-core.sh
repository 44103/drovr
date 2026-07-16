#!/usr/bin/env bash
# drovr: Core library for herdr Socket API communication
# Provides low-level JSON-RPC over Unix socket, pane discovery, and env helpers.
# Agent-agnostic: works with kiro-cli, codex, claude, or any terminal agent.

set -euo pipefail

# --- Configuration -----------------------------------------------------------

DROVR_VERSION="0.1.0"
DROVR_AGENT="${HERDR_AGENT:-unknown}"
DROVR_SOURCE="drovr:${DROVR_AGENT}"

# --- Socket Discovery --------------------------------------------------------

# Discover the herdr socket path.
# Priority: $HERDR_SOCKET_PATH > running default session > search config dir
herdr_socket_path() {
  if [[ -n "${HERDR_SOCKET_PATH:-}" ]] && [[ -S "$HERDR_SOCKET_PATH" ]]; then
    echo "$HERDR_SOCKET_PATH"
    return 0
  fi

  local default_sock="${HOME}/.config/herdr/herdr.sock"
  if [[ -S "$default_sock" ]]; then
    echo "$default_sock"
    return 0
  fi

  # Fallback: find any running session socket
  local sock
  sock=$(find "${HOME}/.config/herdr/sessions" -name "herdr.sock" -type s 2>/dev/null | head -1)
  if [[ -n "$sock" ]]; then
    echo "$sock"
    return 0
  fi

  echo "error: no herdr socket found" >&2
  return 1
}

# --- Pane Discovery ----------------------------------------------------------

# Get the current pane ID.
# Priority: $HERDR_PANE_ID > herdr pane current
herdr_current_pane_id() {
  if [[ -n "${HERDR_PANE_ID:-}" ]]; then
    echo "$HERDR_PANE_ID"
    return 0
  fi

  local result
  result=$(herdr pane current 2>/dev/null) || return 1
  echo "$result" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['result']['pane']['pane_id'])
" 2>/dev/null
}

# --- JSON-RPC over Unix Socket -----------------------------------------------

# Send a JSON-RPC request to the herdr socket and return the response.
# Usage: herdr_rpc <method> <params_json>
# Returns: JSON response on stdout
herdr_rpc() {
  local method="$1"
  local params="${2:-"{}"}"
  local socket_path
  socket_path=$(herdr_socket_path) || return 1

  python3 - "$method" "$params" "$socket_path" "$DROVR_SOURCE" <<'PYTHON'
import json
import socket
import sys
import time
import random

method = sys.argv[1]
params = json.loads(sys.argv[2])
socket_path = sys.argv[3]
source = sys.argv[4]

request_id = f"{source}:{int(time.time() * 1000)}:{random.randrange(1_000_000):06d}"

request = {
    "id": request_id,
    "method": method,
    "params": params,
}

try:
    client = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    client.settimeout(5.0)
    client.connect(socket_path)
    client.sendall((json.dumps(request) + "\n").encode())

    # Read response (may be multiple lines for events, we want the first)
    buffer = b""
    while True:
        chunk = client.recv(8192)
        if not chunk:
            break
        buffer += chunk
        if b"\n" in buffer:
            break

    client.close()

    response_line = buffer.split(b"\n")[0]
    if response_line:
        response = json.loads(response_line)
        print(json.dumps(response))
    else:
        print(json.dumps({"error": {"code": "empty_response", "message": "Empty response from herdr"}}))
        sys.exit(1)
except Exception as e:
    print(json.dumps({"error": {"code": "connection_error", "message": str(e)}}), file=sys.stderr)
    sys.exit(1)
PYTHON
}

# --- Convenience: extract result or error ------------------------------------

# Parse a herdr_rpc response. Prints result JSON on success, error message on failure.
# Usage: response=$(herdr_rpc ...); herdr_result "$response"
herdr_result() {
  local response="$1"
  python3 - "$response" <<'PYTHON'
import json, sys
data = json.loads(sys.argv[1])
if "error" in data:
    err = data["error"]
    print(f"error: {err.get('message', err.get('code', 'unknown'))}", file=sys.stderr)
    sys.exit(1)
if "result" in data:
    print(json.dumps(data["result"]))
else:
    print(json.dumps(data))
PYTHON
}

# --- Request ID Generator ----------------------------------------------------

herdr_request_id() {
  python3 -c "
import time, random, os
agent = os.environ.get('HERDR_AGENT', 'unknown')
print(f'drovr:{agent}:{int(time.time() * 1000)}:{random.randrange(1_000_000):06d}')
"
}

# --- Seq Generator (nanosecond timestamp) ------------------------------------

herdr_seq() {
  python3 -c "import time; print(time.time_ns())"
}
