#!/usr/bin/env bash

# Script dịch các file code (comment, label) từ tiếng Trung sang tiếng Anh
# CHẠY TUẦN TỰ (Single-core) - SỬ DỤNG LM STUDIO API
# Đã tái cấu trúc để dễ gỡ lỗi, loại bỏ "bash -c"

set -euo pipefail

# ==============================
# CONFIGURATION
# ==============================

LOG_FILE="./translation.log"
LM_STUDIO_URL="http://172.16.0.25:1234/v1/chat/completions"

# Định nghĩa các phần của prompt
SYSTEM_PROMPT="You are an expert software developer and a professional translator. Your task is to translate the provided code into English. This includes all comments, documentation, and variable/function names (identifiers) if they are in a non-English language. The translated code should be fully functional, follow standard English coding conventions (e.g., snake_case for variables if the original used it, but with English words), and maintain the original logic and structure."

INSTRUCTIONS="Translate all non-English text in the code—including comments, docstrings, and identifiers—into clear, idiomatic English. Output only the translated code. Do not include any explanations, notes, or additional text."

# THAY ĐỔI: Đã XÓA biến API_TRANSLATE_CMD

# Các định dạng file cần xử lý (không đổi)
TEXT_FILE_PATTERNS=(
  "*.py" "*.js" "*.ts" "*.java" "*.xml" "*.json" "*.yaml" "*.yml"
  "*.md" "*.txt" "*.rst" "*.sh" "*.bash" "*.properties"
  "*.html" "*.css" "*.sql" "*.go" "*.rb" "*.php" "*.c" "*.cpp" "*.h"
  "*.cs" "*.swift" "*.kt" "*.dart"
)

# ==============================
# FUNCTIONS
# ==============================

# Ghi log ra cả console và file (không đổi)
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# THAY ĐỔI: Toàn bộ logic được đưa vào hàm này
# Hàm dịch thuật chính, xử lý từng file
translate_file() {
  local file="$1"
  local temp_out="${file}.translated.tmp"
  trap 'rm -f "$temp_out"' RETURN

  log "➡️  Processing: $file"

  # --- BƯỚC 1: Đọc nội dung file ---
  local input_text
  input_text=$(cat "$file")

  # --- BƯỚC 2: Xây dựng prompt hoàn chỉnh ---
  local full_prompt
  full_prompt=$(printf "<system_prompt>\n%s\n</system_prompt>\n\n<code_file_to_translate>\n%s\n</code_file_to_translate>\n\n<instructions>\n%s\n</instructions>" \
    "$SYSTEM_PROMPT" \
    "$input_text" \
    "$INSTRUCTIONS")

  # --- BƯỚC 3: Tạo JSON và gọi API bằng curl ---
  local api_response
  api_response=$(
    jq -n \
      --arg content_to_translate "$full_prompt" \
      '{
        "model": "qwen3",
        "messages": [ { "role": "user", "content": $content_to_translate } ],
        "temperature": 0.1,
        "stream": false
      }' | curl -s -X POST "$LM_STUDIO_URL" \
               -H "Content-Type: application/json" \
               --data-binary @-
  )

  # Kiểm tra lỗi curl
  if [[ $? -ne 0 ]]; then
      log "❌ Translation failed (curl error): $file"
      return 1
  fi

  # --- BƯỚC 4: Phân tích response và lấy nội dung ---
  local translated_text
  translated_text=$(echo "$api_response" | jq -r ".choices[0].message.content")

  # --- BƯỚC 5: Kiểm tra, LỌC BỎ TAGS, và lưu file ---
  if [[ -z "$translated_text" || "$translated_text" == "null" ]]; then
      log "❌ Translation failed (API returned empty/null): $file"
      log "Raw response: $api_response"
      return 1
  fi

  # THAY ĐỔI: Lọc bỏ các tag ``` ở đầu và cuối
  # Lệnh sed này sẽ:
  # 1{/^\s*```/d;} : Nếu dòng 1 bắt đầu bằng ``` (có thể có khoảng trắng), xóa nó.
  # ${/^\s*```\s*$/d;} : Nếu dòng cuối cùng CHỈ chứa ``` (có thể có khoảng trắng), xóa nó.
  echo "$translated_text" | sed '1{/^\s*```/d;}; ${/^\s*```\s*$/d;}' > "$temp_out"

  # Các bước kiểm tra file (không đổi)
  if [[ ! -s "$temp_out" ]]; then
    log "⚠️  Empty output (skipping): $file"
    return 1
  fi

  if cmp -s "$file" "$temp_out"; then
    log "ℹ️  No changes detected (skipping): $file"
    return 0
  fi

  mv "$temp_out" "$file"
  log "✅ Translated: $file"
}

# Hàm chính (không đổi)
main() {
  local root_dir="${1:-.}"

  if ! command -v curl &> /dev/null; then
    log "❌ ERROR: 'curl' command not found. Please install curl."
    exit 1
  fi
  if ! command -v jq &> /dev/null; then
    log "❌ ERROR: 'jq' command not found. Please install jq."
    exit 1
  fi
  if ! command -v cmp &> /dev/null; then
    log "❌ ERROR: 'cmp' command not found. (Usually part of 'diffutils')"
    exit 1
  fi

  log "🚀 Starting translation (Chinese → English) in: $root_dir"
  log "ℹ️  Using LM Studio API at: $LM_STUDIO_URL"
  log "ℹ️  Using XML prompt structure."
  log "ℹ️  Running in single-core (sequential) mode."

  if [ -d "$root_dir/.git" ]; then
    if ! git -C "$root_dir" diff-index --quiet HEAD --; then
      log "⚠️  WARNING: Git working directory is not clean. Aborting for safety."
      log "Please commit or stash your changes before running this script."
      exit 1
    else
      log "ℹ️  Git directory is clean. Proceeding..."
    fi
  fi

  local find_args=( "$root_dir" -type f \( )
  for i in "${!TEXT_FILE_PATTERNS[@]}"; do
    local pat="${TEXT_FILE_PATTERNS[i]}"
    if [[ $i -eq $(( ${#TEXT_FILE_PATTERNS[@]} - 1 )) ]]; then
      find_args+=( -name "$pat" )
    else
      find_args+=( -name "$pat" -o )
    fi
  done
  find_args+=( \) -print0 )

  while IFS= read -r -d '' file; do
      translate_file "$file" || true
  done < <(find "${find_args[@]}" 2>/dev/null)

  log "🎉 Translation completed."
}

# THAY ĐỔI: Đã XÓA tất cả các lệnh 'export'
# Chúng không còn cần thiết nữa.

# Chạy script
main "$@"