import sys
from openai import OpenAI
import subprocess
import os

# OpenAI API キーの設定
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    print("Error: OPENAI_API_KEY is not set.")
    sys.exit(1)

# OpenAI API Key 設定
client = OpenAI(
    api_key = os.getenv(api_key)
)

# Git の diff を取得
def get_git_diff():
    # Fetch the latest changes from origin
    subprocess.run(['git', 'fetch', 'origin'], check=True)

    # Get the diff between origin/main and the current branch (HEAD)
    result = subprocess.run(['git', 'diff', 'origin/main...HEAD', '--name-only'], stdout=subprocess.PIPE, check=True)
    changes = result.stdout.decode('utf-8').strip()
    return changes

# OpenAI API を使用して PR のタイトルと説明を生成
def generate_pr_description(changes):
    prompt = f"Generate a pull request title and description for the following changes: {changes}"

    chat_completion = client.chat.completions.create(
        model="gpt-4o",
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        temperature=1,
        max_tokens=2048,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0
    )

    # 結果を取得して整形
    completion = chat_completion['choices'][0]['message']['content']
    lines = completion.split("\n")
    pr_title = lines[0]
    pr_body = "\n".join(lines[1:])

    return pr_title, pr_body

# Git の diff を取得
changes = get_git_diff()

print(changes)

# 終了
exit

# PR タイトルと説明を生成
if changes:
    pr_title, pr_body = generate_pr_description(changes)
    print(f"PR Title: {pr_title}")
    print(f"PR Body:\n{pr_body}")
else:
    print("No changes detected.")
