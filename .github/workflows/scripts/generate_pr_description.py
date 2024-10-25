import openai
import os
import subprocess

# OpenAI API キーを設定
openai.api_key = os.getenv("OPENAI_API_KEY")

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

    response = openai.ChatCompletion.create(
        model="gpt-4",  # GPT-3.5の場合は "gpt-3.5-turbo" に変更
        messages=[
            {"role": "system", "content": "あなたは優秀なソフトウェアエンジニアです。"},
            {"role": "user", "content": prompt},
        ],
        max_tokens=500,
        temperature=0.5,
    )

    # 応答の解析
    return response['choices'][0]['message']['content'].strip()

# Git コミットログと差分の取得
def get_commit_logs_and_diffs():
    result = subprocess.run(['git', 'log', 'origin/main..HEAD', '--pretty=format:%h %s'], stdout=subprocess.PIPE, text=True)
    commits = result.stdout.strip().split('\n')

    logs_and_diffs = []
    for commit in commits:
        commit_hash = commit.split()[0]
        diff_result = subprocess.run(['git', 'diff', f'{commit_hash}~1', commit_hash], stdout=subprocess.PIPE, text=True)
        logs_and_diffs.append(f"{commit}\n{diff_result.stdout.strip()}")

    return "\n\n".join(logs_and_diffs)

# メインロジック
if __name__ == "__main__":
    commit_logs_and_diffs = get_commit_logs_and_diffs()

    if commit_logs_and_diffs:
        pr_description = generate_pr_description(commit_logs_and_diffs)
        print(pr_description)
    else:
        print("No new commits detected.")
