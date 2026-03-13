#!/bin/bash
#
# Context7 Documentation Lookup
# Queries the Context7 MCP server for up-to-date library documentation.
#
# Usage:
#   ./lookup.sh resolve "next.js"           # Find library ID
#   ./lookup.sh query <library-id> "topic"  # Query docs for a topic
#   ./lookup.sh search "next.js app router" # Resolve + query in one step

set -euo pipefail

ACTION="${1:?Usage: lookup.sh <resolve|query|search> <args...>}"
shift

CONTEXT7_CMD="npx -y @upstash/context7-mcp"

# Helper: send JSON-RPC to Context7 via stdio
query_context7() {
  local method="$1"
  local params="$2"

  local request="{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"tools/call\",\"params\":{\"name\":\"${method}\",\"arguments\":${params}}}"

  echo "$request" | $CONTEXT7_CMD 2>/dev/null | grep -o '{.*}' | tail -1
}

case "$ACTION" in
  resolve)
    LIBRARY="${1:?Usage: lookup.sh resolve <library-name>}"
    echo "Resolving library: $LIBRARY"
    query_context7 "resolve-library-id" "{\"libraryName\":\"$LIBRARY\"}"
    ;;

  query)
    LIBRARY_ID="${1:?Usage: lookup.sh query <library-id> <topic>}"
    TOPIC="${2:?Usage: lookup.sh query <library-id> <topic>}"
    echo "Querying: $TOPIC (library: $LIBRARY_ID)"
    query_context7 "get-library-docs" "{\"context7CompatibleLibraryID\":\"$LIBRARY_ID\",\"topic\":\"$TOPIC\"}"
    ;;

  search)
    QUERY="${*:?Usage: lookup.sh search <query>}"
    # Extract likely library name (first word or two)
    LIBRARY=$(echo "$QUERY" | awk '{print $1}')
    TOPIC=$(echo "$QUERY" | cut -d' ' -f2-)

    echo "Searching: $QUERY"
    echo "Step 1: Resolving library '$LIBRARY'..."
    RESOLVE_RESULT=$(query_context7 "resolve-library-id" "{\"libraryName\":\"$LIBRARY\"}")
    echo "$RESOLVE_RESULT"

    # Try to extract the library ID
    LIB_ID=$(echo "$RESOLVE_RESULT" | grep -o '"context7CompatibleLibraryID":"[^"]*"' | head -1 | cut -d'"' -f4)

    if [[ -n "$LIB_ID" ]]; then
      echo ""
      echo "Step 2: Querying docs for '$TOPIC'..."
      query_context7 "get-library-docs" "{\"context7CompatibleLibraryID\":\"$LIB_ID\",\"topic\":\"$TOPIC\"}"
    else
      echo "Could not resolve library ID. Try a more specific library name."
    fi
    ;;

  *)
    echo "Unknown action: $ACTION"
    echo "Usage: lookup.sh <resolve|query|search> <args...>"
    exit 1
    ;;
esac
