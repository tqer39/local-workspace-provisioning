#!/usr/bin/env python3
import os
import subprocess
import openai
import sys

# OpenAI API キーの設定
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    print("Error: OPENAI_API_KEY is not set.")
    sys.exit(1)

# Git の差分を取得
diff = subprocess.run(["git", "diff", "origin/main...HEAD"], capture_output=True, text=True).stdout

if not diff.strip():
    print("No changes detected.")
    sys.exit(0)

# OpenAI API を使用して要約を生成
prompt = f"""
以下の Git の差分を読んで、変更内容を簡潔に要約してください。

差分:
{diff}

要約:
"""

try:
    response = openai.Completion.create(
        engine="text-davinci-003",
        prompt=prompt,
        max_tokens=200,
        temperature=0.5,
    )
    summary = response.choices[0].text.strip()
except Exception as e:
    print(f"Error calling OpenAI API: {e}")
    sys.exit(1)

# PR テンプレートを読み込む（存在する場合）
pr_template = ""
template_path = ".github/PULL_REQUEST_TEMPLATE.md"
if os.path.exists(template_path):
    with open(template_path, "r") as f:
        pr_template = f.read()
else:
    # テンプレートがない場合のデフォルト
    pr_template = "# 概要\n\n# 変更点\n\n# 動作確認"

# PR の説明を生成
pr_description = pr_template.replace("# 概要", f"# 概要\n{summary}")

# PR のタイトルを生成（要約の最初の一行を使用）
pr_title = summary.split('\n')[0]

# 結果を出力
print(f"{pr_title}\n\n{pr_description}")
