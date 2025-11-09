#!/usr/bin/env bash

# Script dịch các file code (comment, label) từ tiếng Trung sang tiếng Anh
# CHẠY TUẦN TỰ (Single-core) - SỬ DỤNG LM STUDIO API
# ĐÃ CẬP NHẬT: Tự động chia file lớn thành các chunk nhỏ để dịch

set -euo pipefail

# ==============================
# CONFIGURATION
# ==============================

LOG_FILE="./translation.log"
# THAY ĐỔI: Quay lại endpoint /v1/chat/completions (chuẩn OpenAI hiện tại)
LM_STUDIO_URL="http://172.16.0.25:1234/v1/chat/completions"
# MỚI: Định nghĩa kích thước chunk (số dòng)
# THAY ĐỔI: Giảm CHUNK_SIZE để tránh lỗi "full context" cho 1 chunk
CHUNK_SIZE=200

# Định nghĩa các phần của prompt
SYSTEM_PROMPT="You are an expert software developer and a professional translator. Your task is to translate the provided code into English. This includes all comments, documentation, and variable/function names (identifiers) if they are in a non-English language. The translated code should be fully functional, follow standard English coding conventions (e.g., snake_case for variables if the original used it, but with English words), and maintain the original logic and structure."

INSTRUCTIONS="Translate all non-English text in the code—including comments, docstrings, and identifiers—into clear, idiomatic English. Output only the translated code. Do not include any explanations, notes, or additional text."

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

# THAY ĐỔI: Toàn bộ logic được cập nhật để xử lý chunk
# Hàm dịch thuật chính, xử lý từng file
translate_file() {
  local file="$1"
  local temp_out="${file}.translated.tmp"
  # MỚI: Tạo thư mục tạm để chứa các chunk
  local temp_dir
  temp_dir=$(mktemp -d)

  # MỚI: Trap sẽ dọn dẹp cả file tạm VÀ thư mục chunk
  trap 'rm -f "$temp_out"; rm -rf "$temp_dir"' RETURN

  log "➡️  Processing: $file"

  # --- BƯỚC 1: Chia file thành các chunk ---
  # Sử dụng split để chia file theo số dòng (CHUNK_SIZE)
  # và lưu vào thư mục tạm với prefix 'chunk_'
  split -l "$CHUNK_SIZE" "$file" "$temp_dir/chunk_"
  
  # Đếm số lượng chunk để log
  local chunk_count
  chunk_count=$(find "$temp_dir" -type f -name "chunk_*" | wc -l)
  
  if [[ $chunk_count -gt 1 ]]; then
    log "    File is large, split into $chunk_count chunks of $CHUNK_SIZE lines."
  fi

  # MỚI: Tạo file output rỗng để chuẩn bị ghi nối (append)
  touch "$temp_out"
  local i=0

  # --- BƯỚC 2: Lặp qua từng chunk (đã sắp xếp) và dịch ---
  # Dùng find ... | sort | while read ... để xử lý an toàn
  find "$temp_dir" -type f -name "chunk_*" | sort | while IFS= read -r chunk_file; do
    i=$((i + 1))
    log "    Translating chunk $i/$chunk_count: $(basename "$chunk_file")"

    # --- BƯỚC 2a: Đọc nội dung chunk ---
    local input_text
    input_text=$(cat "$chunk_file")

    # --- BƯỚC 2b: Xây dựng prompt (giống hệt) ---
    local full_prompt
    full_prompt=$(printf "<system_prompt>\n%s\n</system_prompt>\n\n<code_file_to_translate>\n%s\n</code_file_to_translate>\n\n<instructions>\n%s\n</instructions>" \
      "$SYSTEM_PROMPT" \
      "$input_text" \
      "$INSTRUCTIONS")

    # --- BƯỚC 2c: Tạo JSON và gọi API (giống hệt) ---
    local api_response
    api_response=$(
      jq -n \
        --arg content_to_translate "$full_prompt" \
        '{
          "model": "qwen3",
          "messages": [ { "role": "user", "content": $content_to_translate } ],
          "temperature": 0.1,
          "max_tokens": 131000,
          "stream": false
        }' | curl -s -X POST "$LM_STUDIO_URL" \
              -H "Content-Type: application/json" \
              --data-binary @-
    )

    # --- BƯỚC 2d: Kiểm tra lỗi (cho chunk) ---
    if [[ $? -ne 0 ]]; then
      log "❌ Translation failed (curl error) for chunk: $chunk_file"
      return 1 # Thất bại toàn bộ file nếu 1 chunk lỗi
    fi

    local translated_text
    # THAY ĐỔI: Parse response từ endpoint /chat/completions
    translated_text=$(echo "$api_response" | jq -r ".choices[0].message.content")

    if [[ -z "$translated_text" || "$translated_text" == "null" ]]; then
      log "❌ Translation failed (API returned empty/null) for chunk: $chunk_file"
      log "Raw response: $api_response"
      return 1 # Thất bại toàn bộ file
    fi

    # --- BƯỚC 2e: Lọc tag và GHI NỐI (>>) vào file tạm ---
    # Lệnh sed này vẫn hoạt động chính xác vì nó xử lý input (translated_text)
    # chứ không phải toàn bộ file.
    echo "$translated_text" | sed '1{/^\s*```/d;}; ${/^\s*```\s*$/d;}' >> "$temp_out"

    # MỚI: Thêm một dòng mới sau mỗi chunk để đảm bảo
    # file không bị dính liền nếu API bỏ sót
    echo "" >> "$temp_out"

  done # Kết thúc vòng lặp chunk

  # --- BƯỚC 3: Kiểm tra file output cuối cùng (giống hệt) ---
  # Các bước này được thực hiện SAU KHI tất cả các chunk đã được dịch
  # và ghép lại vào $temp_out.

  # Xóa dòng trống cuối cùng (thêm ở 2e)
  # SỬA LỖI: Xóa khoảng trắng trong '$ { ... }' thành '${...}'
  sed -i '${/^\s*$/d;}' "$temp_out"

  if [[ ! -s "$temp_out" ]]; then
    log "⚠️  Empty output after all chunks (skipping): $file"
    return 1
  fi

  if cmp -s "$file" "$temp_out"; then
    log "ℹ️  No changes detected (skipping): $file"
    return 0
  fi

  mv "$temp_out" "$file"
  log "✅ Translated (from $chunk_count chunks): $file"
  # Trap sẽ tự động dọn dẹp $temp_dir và $temp_out
}

# Hàm main (không đổi)
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
  # MỚI: Kiểm tra lệnh 'split' và 'mktemp'
  if ! command -v split &> /dev/null; then
    log "❌ ERROR: 'split' command not found. (Usually part of 'coreutils')"
    exit 1
  fi
  if ! command -v mktemp &> /dev/null; then
    log "❌ ERROR: 'mktemp' command not found. (Usually part of 'coreutils')"
    exit 1
  fi

  log "🚀 Starting translation (Chinese → English) in: $root_dir"
  log "ℹ️  Using LM Studio API at: $LM_STUDIO_URL"
  log "ℹ️  Using XML prompt structure."
  log "ℹ️  Running in single-core (sequential) mode."
  log "ℹ️  Chunk size set to: $CHUNK_SIZE lines."

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
      translate_file "$file" || log "‼️  Error processing $file, skipping to next."
  done < <(find "${find_args[@]}" 2>/dev/null)

  log "🎉 Translation completed."
}

# Chạy script
main "$@"