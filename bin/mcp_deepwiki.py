#!/usr/bin/env python3
import sys
import json
import requests

def query_deepwiki_repo(repo_url: str, question: str = "") -> str:
    """
    Gửi yêu cầu tới MCP DeepWiki để truy vấn thông tin về GitHub repo.
    
    Args:
        repo_url (str): URL GitHub, ví dụ: "https://github.com/ruoyi-cloud/ruoyi"
        question (str): Câu hỏi thêm (tùy chọn)
    
    Returns:
        str: Nội dung phản hồi từ MCP (text thuần)
    """
    url = "https://mcp.deepwiki.com/sse"
    
    # Tạo prompt rõ ràng để MCP hiểu cần truy vấn repo nào
    user_prompt = f"Repository: {repo_url}"
    if question:
        user_prompt += f"\nQuestion: {question}"

    payload = {
        "jsonrpc": "2.0",
        "id": 1,
        "method": "callTool",
        "params": {
            "name": "deepwiki",
            "arguments": {
                "query": user_prompt
            }
        }
    }

    headers = {
        "Content-Type": "application/json"
    }

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        # Xử lý phản hồi JSON-RPC
        if "result" in data:
            result = data["result"]
            if isinstance(result, dict) and "content" in result:
                return result["content"]
            else:
                return str(result)
        elif "error" in data:
            error = data["error"]
            return f"[MCP Error] {error.get('message', 'Unknown error')}"
        else:
            return "[MCP] Unexpected response format"
            
    except requests.exceptions.RequestException as e:
        return f"[MCP Request Error] {str(e)}"
    except Exception as e:
        return f"[MCP Exception] {str(e)}"


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 mcp_deepwiki.py <GITHUB_REPO_URL> [QUESTION]")
        print("Example: python3 mcp_deepwiki.py https://github.com/ruoyi-cloud/ruoyi 'Mô tả kiến trúc?'")
        sys.exit(1)

    repo_url = sys.argv[1]
    question = " ".join(sys.argv[2:]) if len(sys.argv) > 2 else ""

    result = query_deepwiki_repo(repo_url, question)
    print(result)
