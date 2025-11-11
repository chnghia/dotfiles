#!/usr/bin/env bash
# lmchat.sh — terminal chat client for LM Studio (localhost:1234)
# Requires: curl, jq
# Usage:
#   ./lmchat.sh [model] [--system system_prompt.txt]
# Example:
#   ./lmchat.sh "qwen2.5-7b-instruct" --system system.txt

set -euo pipefail

BASE_URL="http://172.16.0.25:1234/v1/chat/completions"
MODEL="${1:-"openai/gpt-oss-20b"}"
SYSTEM_FILE=""
if [[ "${2:-}" == "--system" ]]; then
  SYSTEM_FILE="${3:-}"
fi

TMPDIR=$(mktemp -d)
HISTORY="$TMPDIR/history.json"
trap "rm -rf $TMPDIR" EXIT

# init history
if [[ -n "$SYSTEM_FILE" && -f "$SYSTEM_FILE" ]]; then
  SYS_PROMPT=$(<"$SYSTEM_FILE")
  jq -n --arg sys "$SYS_PROMPT" '[{role:"system", content:$sys}]' > "$HISTORY"
else
  jq -n '[]' > "$HISTORY"
fi

# Detect non-interactive mode (input piped)
if [ ! -t 0 ]; then
  USER_INPUT=$(cat)
  if [ -z "$USER_INPUT" ]; then
    echo "No input provided from stdin." >&2
    exit 1
  fi

  # append system prompt + user message
  jq --arg msg "$USER_INPUT" '. + [{role:"user", content:$msg}]' "$HISTORY" > "$TMPDIR/hist2.json" && mv "$TMPDIR/hist2.json" "$HISTORY"

  PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --argjson messages "$(cat "$HISTORY")" \
    '{model:$model, messages:$messages, stream:true, temperature:0.7}')

  # Stream output
  curl -sN -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | while IFS= read -r line; do
      if [[ "$line" == "data: "* ]]; then
        json="${line#data: }"
        if [[ "$json" == "[DONE]" ]]; then
          break
        fi
        token=$(echo "$json" | jq -r '.choices[0].delta.content // empty' 2>/dev/null || true)
        printf "%s" "$token"
      fi
    done
  echo
  exit 0
fi

echo "LM Studio terminal chat client"
echo "Model: $MODEL"
[[ -n "$SYSTEM_FILE" ]] && echo "System prompt loaded from: $SYSTEM_FILE"
echo "-------------------------------------------"
echo "Type /quit to exit, /clear to clear context."
echo

while true; do
  printf "\nYou: "
  if ! IFS= read -r USER_INPUT; then echo; break; fi

  case "$USER_INPUT" in
    "/quit"|"quit")
      echo "Goodbye."
      break
      ;;
    "/clear")
      if [[ -n "$SYSTEM_FILE" && -f "$SYSTEM_FILE" ]]; then
        SYS_PROMPT=$(<"$SYSTEM_FILE")
        jq -n --arg sys "$SYS_PROMPT" '[{role:"system", content:$sys}]' > "$HISTORY"
      else
        jq -n '[]' > "$HISTORY"
      fi
      echo "(history cleared)"
      continue
      ;;
    "")
      echo "(empty input — skipped)"
      continue
      ;;
  esac

  # append user's message
  jq --arg msg "$USER_INPUT" '. + [{role:"user", content:$msg}]' "$HISTORY" > "$TMPDIR/hist2.json" && mv "$TMPDIR/hist2.json" "$HISTORY"

  # build request payload
  PAYLOAD=$(jq -n \
    --arg model "$MODEL" \
    --argjson messages "$(cat "$HISTORY")" \
    '{model:$model, messages:$messages, stream:true, temperature:0.7}')

  echo -e "\nAssistant:\n"

  # call LM Studio with streaming output
  curl -sN -X POST "$BASE_URL" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" | while IFS= read -r line; do
      # SSE stream: lines start with 'data: {...}'
      if [[ "$line" == "data: "* ]]; then
        json="${line#data: }"
        if [[ "$json" == "[DONE]" ]]; then
          break
        fi
        token=$(echo "$json" | jq -r '.choices[0].delta.content // empty' 2>/dev/null || true)
        printf "%s" "$token"
        ASSISTANT_OUTPUT+="$token"
      fi
    done
  echo

  # append assistant reply to history
  jq --arg msg "${ASSISTANT_OUTPUT:-}" '. + [{role:"assistant", content:$msg}]' "$HISTORY" > "$TMPDIR/hist2.json" && mv "$TMPDIR/hist2.json" "$HISTORY"
  unset ASSISTANT_OUTPUT
done
