#!/usr/bin/env bash

# Script này tìm tất cả các file .java trong thư mục hiện tại
# và các thư mục con, sau đó loại bỏ các tag Markdown code block.

set -e # Thoát ngay nếu có lỗi

# Thư mục cần dọn dẹp (mặc định là thư mục hiện tại)
TARGET_DIR="${1:-.}"

echo "🔍 Bắt đầu dọn dẹp các file .java trong thư mục: $TARGET_DIR"

# Tìm tất cả các file có đuôi .java
# -print0 và -d '' để xử lý tên file có dấu cách
find "$TARGET_DIR" -type f -name "*.java" -print0 | while IFS= read -r -d '' file; do
    
    echo "Processing: $file"
    
    # Tạo một file tạm
    temp_file="${file}.tmp"

    # Lệnh sed mạnh mẽ để xử lý:
    # 1{/^\s*```/d;} :
    #   -> 1{...} = Chỉ áp dụng cho dòng 1.
    #   -> /^\s*```/ = Nếu dòng bắt đầu (^) bằng 0 hoặc nhiều khoảng trắng (\s*)
    #                 theo sau là ```. (Điều này sẽ khớp với "```" và "```java")
    #   -> d = Xóa dòng đó.
    #
    # ${/^\s*```\s*$/d;} :
    #   -> ${...} = Chỉ áp dụng cho dòng cuối cùng ($).
    #   -> /^\s*```\s*$/ = Nếu toàn bộ dòng chỉ chứa ``` (có thể có khoảng trắng).
    #   -> d = Xóa dòng đó.
    
    sed '1{/^\s*```/d;}; ${/^\s*```\s*$/d;}' "$file" > "$temp_file"

    # Ghi đè file gốc bằng file tạm đã được làm sạch
    # (Thêm kiểm tra để đảm bảo file tạm không bị rỗng do lỗi)
    if [[ -s "$temp_file" ]]; then
        mv "$temp_file" "$file"
    else
        echo "⚠️  Cảnh báo: File tạm rỗng, bỏ qua $file"
        # Xóa file tạm nếu nó rỗng
        rm -f "$temp_file"
    fi
done

echo "🎉 Dọn dẹp hoàn tất!"
