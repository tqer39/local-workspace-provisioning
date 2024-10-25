from openai import OpenAI
import os
import subprocess

# OpenAI API キーを設定
api_key = os.getenv("OPENAI_API_KEY")
if not api_key:
    raise ValueError("API key is not set.")

client = OpenAI(
    # This is the default and can be omitted
    api_key = os.getenv("OPENAI_API_KEY")
)

# プロンプトの準備
def create_prompt(commit_logs):
    return f"""
    以下のコミットログとファイルの差分を読んで、わかりやすいプルリクエストのタイトルと詳細な説明を日本語で作成してください。

    コミットログとファイルの差分:
    {commit_logs}

    出力形式:
    タイトル: プルリクエストのタイトル
    説明:
    - 変更点の概要
    - 技術的な詳細や注意点
    """

# OpenAI API でのリクエスト
def generate_pr_description(commit_logs):
    prompt = create_prompt(commit_logs)

    response = client.chat.completions.create(
        model="gpt-4",  # GPT-3.5の場合は "gpt-3.5-turbo" に変更
        messages=[
            {"role": "system", "content": "あなたは優秀なソフトウェアエンジニアです。"},
            {"role": "user", "content": prompt},
        ],
        max_tokens=2000,
        temperature=0.5,
    )

    return response.choices[0].message.content.strip()

# Git コミットログとファイルの差分の取得
def get_commit_logs_and_diffs():
    result = subprocess.run(['git', 'log', '--pretty=format:%H %s', 'origin/main..HEAD', '-n', '50'], capture_output=True, text=True)  # コミットログの数を制限
    commit_logs = result.stdout.strip().split('\n')

    if not commit_logs or commit_logs == ['']:
        return ""

    logs_and_diffs = []
    for commit in commit_logs:
        commit_hash = commit.split()[0]
        if commit_hash:
            diff_result = subprocess.run(['git', 'diff', commit_hash + '^!', '--'], capture_output=True, text=True)
            logs_and_diffs.append(f"Commit: {commit}\nDiff:\n{diff_result.stdout}")

    return "\n\n".join(logs_and_diffs)

# メインロジック
if __name__ == "__main__":
    commit_logs_and_diffs = get_commit_logs_and_diffs()

    if commit_logs_and_diffs:
        pr_description = generate_pr_description(commit_logs_and_diffs)
        print(pr_description)
    else:
        print("No new commits detected.")
