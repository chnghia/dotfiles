#!/usr/bin/env bash
# lmchat.sh — minimal terminal chat client for LM Studio (localhost:1234)
# Requires: curl, jq
# Usage: ./lmchat.sh [model] 
# Example: ./lmchat.sh "lmstudio-community/qwen2.5-7b-instruct"

set -euo pipefail

BASE_URL="${LMSTUDIO_BASE_URL:-http://172.16.0.25:1234/v1}"
MODEL="${1:-"openai/gpt-oss-20b"}"   # default model (tùy bạn đổi)
API_KEY="${LMSTUDIO_API_KEY:-}"      # nếu LM Studio yêu cầu api key (optional)

TMPDIR=$(mktemp -d)
HISTORY="$TMPDIR/history.json"

# init history with an optional system prompt (change if cần)
jq -n '[]' > "$HISTORY"
# Uncomment and edit below to add a system prompt by default:
# jq -n '[{role:"system", content:"You are a helpful assistant."}]' > "$HISTORY"

cleanup() {
  rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "LM Studio terminal chat client"
echo "Base URL: $BASE_URL"
echo "Model: $MODEL"
echo "Type /quit to exit, /clear to clear conversation history."
echo

while true; do
  printf "\nYou: "
  if ! IFS= read -r USER_INP; then
    echo
    break
  fi

  case "$USER_INP" in
    "/quit"|"quit" )
      echo "Goodbye."
      break
      ;;
    "/clear" )
      jq -n '[]' > "$HISTORY"
      echo "Conversation cleared."
      continue
      ;;
    "" )
      echo "(empty input — try again)"
      continue
      ;;
  esac

  # append user's message to history
  jq --arg content "$USER_INP" '. + [{role:"user", content:$content}]' "$HISTORY" > "$TMPDIR/history2.json" && mv "$TMPDIR/history2.json" "$HISTORY"

  # build payload
  PAYLOAD=$(jq -n --arg model "$MODEL" --argjson messages "$(cat $HISTORY)" \
    '{model:$model, messages:$messages, temperature:0.7, max_tokens:-1, stream:false}')

  # prepare curl headers
  AUTH_HEADER=()
  if [ -n "$API_KEY" ]; then
    # some setups expect Authorization: Bearer <key> (if LM Studio configured)
    AUTH_HEADER=(-H "Authorization: Bearer $API_KEY")
  fi

  # call LM Studio OpenAI-compatible endpoint
  RESP=$(curl -H "Content-Type: application/json" \
    -d "$PAYLOAD" "$BASE_URL/chat/completions")

  # Try to extract assistant text — handle both OpenAI-style and LM Studio v0 api variations
  # OpenAI-compatible: .choices[0].message.content
  # v0/chat/completions: .choices[0].message.content also common
  ASSISTANT_TEXT=$(echo "$RESP" | jq -r '.choices[0].message.content // .choices[0].text // ""' 2>/dev/null || true)

  if [ -z "$ASSISTANT_TEXT" ]; then
    echo "No assistant text found. Raw response:"
    echo "$RESP" | sed 's/^/  /'
    # optionally append a placeholder assistant message to history so context keeps going
    jq --arg content "((no assistant reply — raw response printed))" '. + [{role:"assistant", content:$content}]' "$HISTORY" > "$TMPDIR/history2.json" && mv "$TMPDIR/history2.json" "$HISTORY"
    continue
  fi

  # print assistant output nicely
  echo -e "\nAssistant:\n$ASSISTANT_TEXT"

  # append assistant to history
  jq --arg content "$ASSISTANT_TEXT" '. + [{role:"assistant", content:$content}]' "$HISTORY" > "$TMPDIR/history2.json" && mv "$TMPDIR/history2.json" "$HISTORY"
done

