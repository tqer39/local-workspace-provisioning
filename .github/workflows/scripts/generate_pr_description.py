import openai
import os
import subprocess

# OpenAI API キーを設定
openai.api_key = os.getenv("OPENAI_API_KEY")

# プロンプトの準備
def create_prompt(commit_logs):
    return f"""
    以下のコミットログを読んで、わかりやすいプルリクエストのタイトルと詳細な説明を日本語で作成してください。

    コミットログ:
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

# Git コミットログの取得
def get_commit_logs():
    result = subprocess.run(['git', 'log', 'origin/main..HEAD', '--pretty=format:%h %s'],
                            stdout=subprocess.PIPE, text=True)
    return result.stdout.strip()

# メインロジック
if __name__ == "__main__":
    commit_logs = get_commit_logs()

    if commit_logs:
        pr_description = generate_pr_description(commit_logs)
        print(pr_description)
    else:
        print("No new commits detected.")
