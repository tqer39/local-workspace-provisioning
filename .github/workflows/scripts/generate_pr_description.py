import openai
import subprocess

# OpenAI API Key 設定
openai.api_key = os.getenv('OPENAI_API_KEY')

# Git の diff を取得
def get_git_diff():
    result = subprocess.run(['git', 'diff', '--name-only'], stdout=subprocess.PIPE)
    changes = result.stdout.decode('utf-8').strip()
    return changes

# OpenAI API を使用して PR のタイトルと説明を生成
def generate_pr_description(changes):
    prompt = f"Generate a pull request title and description for the following changes: {changes}"

    response = openai.ChatCompletion.create(
        model="gpt-4",
        messages=[{"role": "system", "content": prompt}],
        temperature=1,
        max_tokens=2048,
        top_p=1,
        frequency_penalty=0,
        presence_penalty=0
    )

    # 結果を取得して整形
    completion = response['choices'][0]['message']['content']
    lines = completion.split("\n")
    pr_title = lines[0]
    pr_body = "\n".join(lines[1:])

    return pr_title, pr_body

# Git の diff を取得
changes = get_git_diff()

# PR タイトルと説明を生成
if changes:
    pr_title, pr_body = generate_pr_description(changes)
    print(f"PR Title: {pr_title}")
    print(f"PR Body:\n{pr_body}")
else:
    print("No changes detected.")
