#!/bin/bash

# anyenv と pyenv のアンインストールスクリプト

set -e

echo "🧹 anyenv と pyenv のアンインストールを開始します..."

# 1. anyenv 関連の環境変数とパスを削除
echo "📝 anyenv 関連の設定を削除しています..."

# .zshrc から anyenv 関連の設定を削除
if [ -f "$HOME/.zshrc" ]; then
    sed -i.bak '/anyenv/d' "$HOME/.zshrc"
    echo "✅ .zshrc から anyenv 設定を削除しました"
fi

# .bashrc から anyenv 関連の設定を削除
if [ -f "$HOME/.bashrc" ]; then
    sed -i.bak '/anyenv/d' "$HOME/.bashrc"
    echo "✅ .bashrc から anyenv 設定を削除しました"
fi

# .bash_profile から anyenv 関連の設定を削除
if [ -f "$HOME/.bash_profile" ]; then
    sed -i.bak '/anyenv/d' "$HOME/.bash_profile"
    echo "✅ .bash_profile から anyenv 設定を削除しました"
fi

# 2. anyenv ディレクトリを削除
if [ -d "$HOME/.anyenv" ]; then
    echo "🗂️ $HOME/.anyenv ディレクトリを削除しています..."
    rm -rf "$HOME/.anyenv"
    echo "✅ anyenv ディレクトリを削除しました"
else
    echo "ℹ️ anyenv ディレクトリは存在しません"
fi

# 3. Homebrew から anyenv をアンインストール
if command -v brew &> /dev/null; then
    if brew list anyenv &> /dev/null; then
        echo "🍺 Homebrew から anyenv をアンインストールしています..."
        brew uninstall anyenv
        echo "✅ Homebrew から anyenv をアンインストールしました"
    else
        echo "ℹ️ Homebrew に anyenv はインストールされていません"
    fi
fi

# 4. 個別の *env ディレクトリも削除（念のため）
ENVS=("pyenv" "nodenv" "rbenv" "goenv" "tfenv")
for env in "${ENVS[@]}"; do
    if [ -d "$HOME/.$env" ]; then
        echo "🗂️ $HOME/.$env ディレクトリを削除しています..."
        rm -rf "$HOME/.$env"
        echo "✅ $env ディレクトリを削除しました"
    fi
done

# 5. シェル設定ファイルから pyenv 関連の設定も削除
echo "📝 pyenv 関連の設定を削除しています..."

# .zshrc から pyenv 関連の設定を削除
if [ -f "$HOME/.zshrc" ]; then
    sed -i.bak '/pyenv/d' "$HOME/.zshrc"
    echo "✅ .zshrc から pyenv 設定を削除しました"
fi

# .bashrc から pyenv 関連の設定を削除
if [ -f "$HOME/.bashrc" ]; then
    sed -i.bak '/pyenv/d' "$HOME/.bashrc"
    echo "✅ .bashrc から pyenv 設定を削除しました"
fi

# .bash_profile から pyenv 関連の設定を削除
if [ -f "$HOME/.bash_profile" ]; then
    sed -i.bak '/pyenv/d' "$HOME/.bash_profile"
    echo "✅ .bash_profile から pyenv 設定を削除しました"
fi

# 6. システムのPython3を使用するように設定
echo "🐍 システムのPython3を使用するように設定しています..."

# pyenv でインストールした Python への参照を削除
unset PYENV_ROOT
export PATH=$(echo "$PATH" | sed -e 's/:*[^:]*\.anyenv[^:]*//g' -e 's/:*[^:]*\.pyenv[^:]*//g')

echo ""
echo "✅ anyenv と pyenv のアンインストールが完了しました！"
echo ""
echo "📋 変更内容:"
echo "  - anyenv ディレクトリ (~/.anyenv) を削除"
echo "  - pyenv ディレクトリ (~/.pyenv) を削除"
echo "  - シェル設定ファイルから anyenv/pyenv 関連設定を削除"
echo "  - Homebrew から anyenv をアンインストール"
echo ""
echo "⚠️ 注意事項:"
echo "  - システムのPython3を使用するようになります"
echo "  - 今後はuvを使用してPythonプロジェクトを管理してください"
echo "  - Node.jsが必要な場合は直接Homebrewでインストールしてください"
echo ""
echo "🔄 変更を反映するために、ターミナルを再起動するか以下を実行してください:"
echo "  source ~/.zshrc  # zshを使用している場合"
echo "  source ~/.bashrc # bashを使用している場合"
