#!/bin/bash
#
#--------------------------------------------------
# GEMINI/LM STUDIO DAILY LOG FUNCTION (v5.0)
# Hỗ trợ Zsh/Bash, ước lượng 'po', hỗ trợ chuyển đổi backend
# Đã refactor các prompt ra hàm riêng để dễ bảo trì.
#
# Cách dùng:
#   - Dùng Gemini (mặc định): log plan "làm việc A"
#   - Dùng LM Studio: LOG_ENGINE=local log plan "làm việc A"
#   - Hoặc set mặc định: export LOG_ENGINE=local
#--------------------------------------------------

function log() {
    # --- Định nghĩa Template (Lấy từ v3.0) ---
    local TEMPLATE_EOD="
- Completed: -/10 po
- Issues:
- Tomorrow: "

    local TEMPLATE_FULL="
Following “The Habits”
Daily Plan (1 po):
[Nội dung Daily Plan]
Progress Tracking:
[Nội dung Progress Tracking]
Notes & Links:
[User sẽ tự điền]
End-of-day Report (1 po):
- Completed: -/10 po
- Issues:
- Tomorrow: "

    # --- [PHẦN MỚI] ĐỊNH NGHĨA CÁC HÀM PROMPT ---
    # Các hàm này được đặt bên trong 'log' để tránh xung đột tên.

    # Hàm tạo prompt cho 'plan'
    function _log_prompt_plan() {
        local MEMO="$1"
        # Dùng 'cat <<EOF' để dễ đọc và xử lý các dấu ngoặc kép
        cat <<EOF
Bạn là trợ lý AI. Nhận memo sau và chuyển nó thành các tasks (dùng gạch đầu dòng '-') cho mục 'Daily Plan'.
**Quan trọng: Với mỗi task, hãy ước lượng số Pomodoro (po) cần thiết và ghi ở cuối, ví dụ: '- Task A (2 po)'.**
**Nếu bạn không chắc chắn về số po, hãy thêm dấu chấm hỏi, ví dụ: '(1? po)' hoặc '(2? po)'.**
Chỉ output danh sách các gạch đầu dòng, không giải thích gì thêm.
Memo: "$MEMO"
EOF
    }

    # Hàm tạo prompt cho 'progress'
    function _log_prompt_progress() {
        local MEMO="$1"
        cat <<EOF
Bạn là trợ lý AI. Nhận memo sau và tóm tắt nó (dùng gạch đầu dòng) cho mục 'Progress Tracking' trong Notion. Giữ văn phong súc tích.
**Quan trọng: Với các task hãy cố gắng chia các task thành công việc cụ thể, ví du: '- Task A thực hiện công việc'**
**Xác định các task công việc cha con rõ ràng và súc tích**
Chỉ output danh sách với các gạch đầu dòng theo từng task cha / con
Memo: "$MEMO"
EOF
    }

    # Hàm tạo prompt cho 'eod'
    function _log_prompt_eod() {
        local MEMO="$1"
        local TEMPLATE="$2"
        cat <<EOF
Bạn là trợ lý AI. Nhận memo sau và điền vào template 'End-of-day Report' sau:
\`\`\`
$TEMPLATE
\`\`\`
Hãy **suy luận số po 'Completed' (ví dụ: 7/10 po) dựa trên khối lượng công việc trong memo một cách hợp lý nhất.**
**Nếu bạn không chắc chắn về số po đã hoàn thành, bạn có thể ghi '(7?/10 po)' hoặc '(?/10 po)' để người dùng tự điều chỉnh.**
Hãy cũng tự suy luận để điền vào các mục 'Issues' và 'Tomorrow'.
Chỉ output phần template đã điền, không giải thích gì thêm.
Memo: "$MEMO"
EOF
    }

    # Hàm tạo prompt cho 'full'
    function _log_prompt_full() {
        local MEMO="$1"
        local TEMPLATE="$2"
        cat <<EOF
Bạn là trợ lý AI. Dựa vào memo tổng hợp trong ngày sau đây, hãy tạo toàn bộ nội dung cho trang Notion Daily Journal.
Template gốc:
\`\`\`
$TEMPLATE
\`\`\`
Hãy phân tích memo và điền thông tin vào các mục.
**Yêu cầu quan trọng:**
1.  Khi điền 'Daily Plan', hãy **ước lượng Pomodoro (po) cho mỗi task** (ví dụ: '- Task A (2 po)').
2.  Khi điền 'End-of-day Report', hãy **ước lượng số po đã hoàn thành** (ví dụ: 'Completed: 7/10 po').
3.  **Nếu bạn không chắc chắn về bất kỳ ước lượng po nào, hãy thêm dấu chấm hỏi '?'** (ví dụ: '(2? po)' hoặc 'Completed: 7?/10 po').
4.  Mục 'Notes & Links' để trống.
**Yêu cầu output:** Chỉ output nội dung đã được điền vào template, bắt đầu từ 'Following “The Habits”'. Không giải thích.
Memo tổng hợp: "$MEMO"
EOF
    }

    # --- Hiển thị Hướng dẫn sử dụng (Không đổi) ---
    if [[ "$1" == "help" ]] || [[ "$1" == "--help" ]] || [[ -z "$1" ]]; then
        echo "Cách dùng: log [command] [nội dung memo]"
        echo ""
        echo "Backend được điều khiển bởi biến môi trường \$LOG_ENGINE:"
        echo "  - Không set (mặc định): Dùng Gemini CLI (v2.0)"
        echo "  - 'local' hoặc 'lmstudio': Dùng LM Studio (v3.0) tại http://172.16.0.25:1234"
        echo ""
        echo "Commands:"
        echo "  plan     <memo> : Tạo tasks cho 'Daily Plan' (có ước lượng 'po')"
        echo "  progress <memo> : Ghi nhận cho 'Progress Tracking'"
        echo "  eod      <memo> : Tạo 'End-of-day Report' (có ước lượng 'po' hoàn thành)"
        echo "  full     <memo> : Tạo toàn bộ file log (có ước lượng 'po')"
        echo "  help            : Hiển thị trợ giúp này"
        return 0
    fi

    # --- Xử lý input (Không đổi) ---
    local COMMAND=$1
    shift
    local MEMO="$@"
    local PROMPT=""

    if [[ -z "$MEMO" ]]; then
        echo "Lỗi: Cần có nội dung memo." >&2
        log help
        return 1
    fi

    # --- [ĐÃ THAY ĐỔI] Xây dựng Prompt cho LLM ---
    # Case statement giờ chỉ gọi các hàm helper, gọn gàng hơn
    case "$COMMAND" in
        plan)
            PROMPT=$(_log_prompt_plan "$MEMO")
            ;;
        progress)
            PROMPT=$(_log_prompt_progress "$MEMO")
            ;;
        eod)
            PROMPT=$(_log_prompt_eod "$MEMO" "$TEMPLATE_EOD")
            ;;
        full)
            PROMPT=$(_log_prompt_full "$MEMO" "$TEMPLATE_FULL")
            ;;
        *)
            echo "Lỗi: Command '$COMMAND' không hợp lệ." >&2
            log help
            return 1
            ;;
    esac

    # --- [PHẦN GỘP] ---
    # Kiểm tra biến $LOG_ENGINE để chọn backend (Không đổi)
    #-------------------------------------------------

    if [[ "$LOG_ENGINE" == "local" ]] || [[ "$LOG_ENGINE" == "lmstudio" ]]; then
        # --- Logic của LM Studio (v3.0) ---
        echo "Đang xử lý memo với LM Studio (Local)..." >&2

        # !! BẠN PHẢI THAY THẾ GIÁ TRỊ NÀY BẰNG MODEL CỦA BẠN !!
        local LOCAL_MODEL_NAME="qwen/qwen3-coder-30b"

        # Dùng 'jq' để build JSON một cách an toàn
        local JSON_PAYLOAD
        JSON_PAYLOAD=$(jq -n \
                         --arg prompt_content "$PROMPT" \
                         --arg model_name "$LOCAL_MODEL_NAME" \
                         '{
                            "model": $model_name,
                            "messages": [{"role": "user", "content": $prompt_content}],
                            "temperature": 0.7,
                            "stream": false
                         }')

        # Kiểm tra nếu jq thất bại
        if [[ $? -ne 0 ]]; then
            echo "Lỗi: 'jq' thất bại khi tạo JSON payload." >&2
            echo "Hãy đảm bảo 'jq' đã được cài đặt." >&2
            return 1
        fi

        # Gọi API bằng curl và dùng jq/awk để trích xuất câu trả lời
        curl -s http://172.16.0.25:1234/v1/chat/completions \
             -H "Content-Type: application/json" \
             -d "$JSON_PAYLOAD" | \
             jq -r '.choices[0].message.content' | \
             awk -v RS="</think>" '{sub(/<think>.*/, ""); printf "%s", $0}'

    else
        # --- Logic của Gemini (v2.0) ---
        echo "Đang xử lý memo với Gemini (v2.0)..." >&2

        # (Hãy đảm bảo gemini-cli của bạn có thể truy cập được)
        (cd ~/.gemini-daily && gemini "$PROMPT")
    fi
}

# --- Hướng dẫn thêm alias (để tham khảo) ---
# Bạn có thể thêm vào file .zshrc hoặc .bashrc của mình:
#
# source "/đường/dẫn/đến/file/daily_log.sh"
#
# # Alias cho Gemini (mặc định)
# alias log='log'
#
# # Alias riêng cho LM Studio
# alias loglm='LOG_ENGINE=local log'
#
