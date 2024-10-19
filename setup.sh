#!/bin/bash

# 作業ディレクトリの設定
OWNER="tqer39"  # あなたのGitHubのユーザー名に変更してください
WORKSPACE="$HOME/workspace"
REPO_NAME="local-workspace-provisioning"
DOTFILES_DIR="${WORKSPACE}/${REPO_NAME}"
REPO_URL="https://github.com/${OWNER}/${REPO_NAME}.git"

# CI環境で実行されているか確認
if [ -n "$CI" ]; then
    echo "CI環境で実行されています。"

    # GUIアプリケーションのインストールをスキップ
    INSTALL_GUI_APPS=false
else
    INSTALL_GUI_APPS=true
fi

# OSタイプの取得
OS_TYPE="$(uname -s)"

# 管理者権限の確認
if [ "$EUID" -ne 0 ]; then
    SUDO='sudo'
else
    SUDO=''
fi

# パッケージマネージャの判定と apt/apt-get の選択
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [ -f /etc/debian_version ]; then
        if command -v apt &> /dev/null; then
            PACKAGE_MANAGER="apt"
        else
            PACKAGE_MANAGER="apt-get"
        fi
    elif [ -f /etc/redhat-release ]; then
        PACKAGE_MANAGER="yum"
    else
        echo "サポートされていないLinuxディストリビューションです。手動で必要なパッケージをインストールしてください。"
        exit 1
    fi
fi

# 必要なコマンドのインストール確認とインストール関数
install_if_missing() {
    local cmd="$1"
    local install_cmd="$2"
    if ! command -v "$cmd" &> /dev/null; then
        echo "$cmd がインストールされていません。インストールを試みます。"
        eval "$install_cmd"
        if ! command -v "$cmd" &> /dev/null; then
            echo "$cmd のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "$cmd のインストールが完了しました。"
        fi
    else
        echo "$cmd は既にインストールされています。"
    fi
}

# curl のインストール確認
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
        install_if_missing "curl" "$SUDO $PACKAGE_MANAGER update && $SUDO $PACKAGE_MANAGER install -y curl"
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        install_if_missing "curl" "$SUDO yum install -y curl"
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    echo "macOSでは通常curlがプリインストールされています。"
fi

# git のインストール確認
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
        install_if_missing "git" "$SUDO $PACKAGE_MANAGER update && $SUDO $PACKAGE_MANAGER install -y git"
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        install_if_missing "git" "$SUDO yum install -y git"
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    if ! command -v git &> /dev/null; then
        echo "git がインストールされていません。インストールを試みます。"
        xcode-select --install
        echo "Xcode Command Line Tools のインストールが必要です。インストールが完了したら、再度スクリプトを実行してください。"
        exit 1
    else
        echo "git は既にインストールされています。"
    fi
fi

# brew のインストール確認
if ! command -v brew &> /dev/null; then
    echo "Homebrew がインストールされていません。インストールを試みます。"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # CI 環境でのみ eval コマンドを実行
    if [[ "$CI" == "true" ]]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
    # brew がインストールされたか確認
    if ! command -v brew &> /dev/null; then
        echo "Homebrew のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "Homebrew のインストールが完了しました。"
    fi
else
    echo "Homebrew は既にインストールされています。"
fi

# 必要なパッケージのインストール（Linuxbrew の場合、パスを通す必要があるかもしれません）
if [[ "$OS_TYPE" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ~/workspace ディレクトリを作成
if [ ! -d "$WORKSPACE" ]; then
    echo "$WORKSPACE を作成します..."
    mkdir -p "$WORKSPACE"
fi

# リポジトリをクローンまたは既存のリポジトリを使用
if [ "$CI" == "true" ]; then
    echo "CI環境で実行されています。既存のリポジトリを使用します。"
    DOTFILES_DIR="$GITHUB_WORKSPACE"
else
    if [ ! -d "$DOTFILES_DIR" ]; then
        echo "dotfiles を $DOTFILES_DIR にクローンします..."
        git clone "$REPO_URL" "$DOTFILES_DIR"
        if [ $? -ne 0 ]; then
            echo "リポジトリのクローンに失敗しました。"
            exit 1
        fi
    else
        echo "dotfiles は既に存在します。最新の変更を取得します..."
        git -C "$DOTFILES_DIR" pull
    fi
fi

# dotfiles のシンボリックリンクを作成
echo "シンボリックリンクを作成します..."

# リンクしたい dotfile を個別に指定
DOTFILES=(
    ".zshrc"
    # 他の dotfile を追加
)

for file in "${DOTFILES[@]}"; do
    source_file="$DOTFILES_DIR/$file"
    target_file="$HOME/$file"

    if [ -e "$source_file" ]; then
        ln -sf "$source_file" "$target_file"
        if [ $? -eq 0 ]; then
            echo "シンボリックリンクを作成しました: $target_file"
        else
            echo "シンボリックリンクの作成に失敗しました: $target_file"
        fi
    else
        echo "ファイルが存在しません: $source_file"
    fi
done

# zsh のインストール確認
install_if_missing "zsh" "$SUDO brew install zsh"

# デフォルトシェルを zsh に変更
CURRENT_SHELL=$(basename "$SHELL")
if [ "$CURRENT_SHELL" != "zsh" ]; then
    ZSH_PATH=$(which zsh)
    if chsh -s "$ZSH_PATH"; then
        echo "デフォルトのシェルを zsh ($ZSH_PATH) に変更しました。"
    else
        echo "デフォルトのシェルの変更に失敗しました。管理者権限が必要な場合があります。"
    fi
else
    echo "デフォルトのシェルは既に zsh です。"
fi

# Rancher Desktop のインストール
echo "Rancher Desktop をインストールします..."

if [[ "$OS_TYPE" == "Linux" ]]; then
    # Linux の場合
    if ! command -v rancher-desktop &> /dev/null; then
        echo "Rancher Desktop をインストールします。"
        # Debian/Ubuntu 系の場合
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            curl -fsSL https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | $SUDO gpg --dearmor -o /usr/share/keyrings/rancher-desktop-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/rancher-desktop-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ /" | $SUDO tee /etc/apt/sources.list.d/rancher-desktop.list
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y rancher-desktop
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            $SUDO curl -fsSL https://download.opensuse.org/repositories/isv:Rancher:stable/rpm.repo -o /etc/yum.repos.d/rancher-desktop.repo
            $SUDO yum install -y rancher-desktop
        else
            echo "Rancher Desktop のインストール方法が不明です。手動でインストールしてください。"
            exit 1
        fi
    else
        echo "Rancher Desktop は既にインストールされています。"
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    # macOS の場合
    brew install --cask rancher
else
    echo "サポートされていないOSです。Rancher Desktop のインストールをスキップします。"
fi

# Hyper.js のインストール
echo "Hyper.js をインストールします..."

if [[ "$OS_TYPE" == "Linux" ]]; then
    if ! command -v snap &> /dev/null; then
        echo "snapd がインストールされていません。インストールを試みます。"
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y snapd
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            $SUDO yum install -y epel-release
            $SUDO yum install -y snapd
        fi
        $SUDO systemctl enable --now snapd.socket
        $SUDO ln -s /var/lib/snapd/snap /snap
    fi
    $SUDO snap install hyper --classic
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install --cask hyper
fi

# anyenv のインストール
echo "anyenv をインストールします..."
install_if_missing "anyenv" "brew install anyenv"

# anyenv の初期化
if [ ! -d "$HOME/.anyenv" ]; then
    echo "anyenv を初期化します..."
    anyenv init
    if [ $? -ne 0 ]; then
        echo "anyenv の初期化に失敗しました。"
        exit 1
    fi
else
    echo "anyenv は既に初期化されています。"
fi

# シェルに anyenv のパスを追加（dotfiles で管理されている前提）
# eval "$(anyenv init -)" は .bashrc や .zshrc に含まれている前提

# nodenv, pyenv, tfenv のインストール
ENVS=("nodenv" "pyenv" "tfenv")

for env in "${ENVS[@]}"; do
    if [ ! -d "$HOME/.anyenv/envs/$env" ]; then
        echo "$env をインストールします..."
        anyenv install "$env"
    else
        echo "$env は既にインストールされています。"
    fi
done

# direnv のインストール
echo "direnv をインストールします..."
install_if_missing "direnv" "brew install direnv"

# direnv の初期化（dotfiles で管理されている前提）
# eval "$(direnv hook zsh)" は .zshrc に含まれている前提

# starship のインストール
echo "starship をインストールします..."
install_if_missing "starship" "brew install starship"

# starship の設定ファイルを作成またはシンボリックリンク（dotfiles で管理している前提）
STARSHIP_CONFIG="$HOME/.config/starship.toml"
if [ ! -e "$STARSHIP_CONFIG" ]; then
    mkdir -p "$HOME/.config"
    ln -sf "$DOTFILES_DIR/starship.toml" "$STARSHIP_CONFIG"
    echo "starship の設定ファイルをリンクしました: $STARSHIP_CONFIG"
fi

# aws cli のインストール
echo "AWS CLI をインストールします..."
install_if_missing "aws" "brew install awscli"

# aws-vault のインストール
echo "aws-vault をインストールします..."
install_if_missing "aws-vault" "brew install --cask aws-vault"

# jq のインストール
echo "jq をインストールします..."
install_if_missing "jq" "brew install jq"

# gh (GitHub CLI) のインストール
echo "GitHub CLI をインストールします..."
install_if_missing "gh" "brew install gh"

# Visual Studio Code のインストール
echo "Visual Studio Code をインストールします..."
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
        curl https://packages.microsoft.com/keys/microsoft.asc | $SUDO gpg --dearmor -o /usr/share/keyrings/packages.microsoft.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
        https://packages.microsoft.com/repos/code stable main" | $SUDO tee /etc/apt/sources.list.d/vscode.list
        $SUDO $PACKAGE_MANAGER update
        $SUDO $PACKAGE_MANAGER install -y code
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        $SUDO sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
        $SUDO yum check-update
        $SUDO yum install -y code
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install --cask visual-studio-code
fi

echo "セットアップが完了しました！"

# 再起動の提案
echo "変更を反映するために、ログアウトして再度ログインするか、システムを再起動することをおすすめします。"
