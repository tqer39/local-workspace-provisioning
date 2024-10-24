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

# 最新の origin/main を取得
subprocess.run(['git', 'fetch', 'origin'], check=True)

# origin/main と現在のブランチ間のコミットログを取得
result = subprocess.run(
    ['git', 'log', 'origin/main..HEAD', '--pretty=format:%h %s'],
    stdout=subprocess.PIPE,
    check=True,
    text=True
)
commit_logs = result.stdout.strip()

if not commit_logs:
    print("No new commits detected.")
    sys.exit(0)

# OpenAI API へのプロンプトを作成
system_message = "あなたは優秀なソフトウェアエンジニアです。"
user_message = f"""
以下のコミットログを読んで、わかりやすいプルリクエストのタイトルと詳細な説明を日本語で作成してください。

コミットログ:
{commit_logs}

出力形式:
タイトル: プルリクエストのタイトル
説明:
- 変更点の概要
- 技術的な詳細や注意点
"""

try:
    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[
            {"role": "system", "content": system_message},
            {"role": "user", "content": user_message}
        ],
        max_tokens=500,
        temperature=0.5,
    )
    completion = response.choices[0].message.content.strip()
except Exception as e:
    print(f"Error calling OpenAI API: {e}")
    sys.exit(1)

# PR タイトルと説明を抽出
lines = completion.strip().split('\n', 1)
pr_title_line = lines[0].strip()
pr_body = lines[1].strip() if len(lines) > 1 else ''

# タイトルの前に "タイトル:" が含まれている場合、それを除去
if pr_title_line.startswith("タイトル:"):
    pr_title = pr_title_line.replace("タイトル:", "").strip()
else:
    pr_title = pr_title_line

# 結果を出力
print(f"{pr_title}\n\n{pr_body}")
