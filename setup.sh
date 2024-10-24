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
        echo "❌ サポートされていないLinuxディストリビューションです。手動で必要なパッケージをインストールしてください。"
        exit 1
    fi
fi

# 必要なコマンドのインストール確認とインストール関数
install_if_missing() {
    local cmd="$1"
    local install_cmd="$2"
    echo "$cmd のインストールを確認します..."
    if ! command -v "$cmd" &> /dev/null; then
        echo "$cmd がインストールされていません。インストールを試みます。"
        if [[ "$install_cmd" == *"brew"* ]]; then
            brew install "$cmd"
        else
            $SUDO bash -c "$install_cmd"
        fi

        if ! command -v "$cmd" &> /dev/null; then
            echo "❌ $cmd のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "$cmd --version: $($cmd --version)"
            echo "✅ $cmd のインストールが完了しました。"
        fi
    else
        echo "$cmd --version: $($cmd --version)"
        echo "✅ $cmd は既にインストールされています。"
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
    echo "✅ macOSでは通常curlがプリインストールされています。"
fi

# pbcopy/pbpaste のセットアップ
if [[ "$OS_TYPE" == "Linux" ]]; then
    if ! command -v pbcopy &> /dev/null; then
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            $SUDO $PACKAGE_MANAGER install -y xsel
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            $SUDO yum install xclip
        fi

        if ! command -v xsel &> /dev/null; then
            echo "❌ pbcopy/pbpaste のセットアップに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "✅ pbcopy/pbpaste のセットアップをしました"
        fi
    else
        echo "✅ pbcopy/pbpaste は既にインストールされています。"
    fi
    # macOS では pbcopy/pbpaste がデフォルトで使える
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
        echo "❌ Homebrew のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ Homebrew のインストールが完了しました。"
        if [[ "$OS_TYPE" == "Linux" ]]; then
            # Linuxbrew の場合、ビルドに必要なパッケージをインストール
            if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
                $SUDO $PACKAGE_MANAGER update
                $SUDO $PACKAGE_MANAGER install -y build-essential
            elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
                $SUDO yum install -y gcc make
            fi
        fi
    fi
else
    echo "✅ Homebrew は既にインストールされています。"
fi

# git のインストール確認
if ! command -v git &> /dev/null; then
    if [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            install_if_missing "git" "$SUDO $PACKAGE_MANAGER update && $SUDO $PACKAGE_MANAGER install -y git"
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            install_if_missing "git" "$SUDO yum install -y git"
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        if ! command -v git &> /dev/null; then
            install_if_missing "git" "brew install git"
        fi
    fi

    if ! command -v git &> /dev/null; then
        echo "❌ git のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ git のインストールが完了しました。"
    fi
else
    echo "✅ git は既にインストールされています。"
fi

# 必要なパッケージのインストール（Linuxbrew の場合、パスを通す必要があるかもしれません）
if [[ "$OS_TYPE" == "Linux" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# workspace ディレクトリを作成
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
            echo "❌ リポジトリのクローンに失敗しました。"
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
    ".config/starship.toml"
    ".bash_profile"
    ".bashrc"
    ".gitconfig"
    ".hyper.js"
    ".zshrc"
    # 他の dotfile を追加
)

for file in "${DOTFILES[@]}"; do
    source_file="$DOTFILES_DIR/$file"
    target_file="$HOME/$file"

    if [ -e "$source_file" ]; then
        ln -sf "$source_file" "$target_file"
        if [ $? -eq 0 ]; then
            echo "✅ シンボリックリンクを作成しました: $target_file"
        else
            echo "❌ シンボリックリンクの作成に失敗しました: $target_file"
        fi
    else
        echo "❌ ファイルが存在しません: $source_file"
    fi
done

# zsh
install_if_missing "zsh" "brew install zsh"

# デフォルトシェルを zsh に変更 (CI環境ではスキップ)
if [ "$CI" != "true" ]; then
    CURRENT_SHELL=$(basename "$SHELL")
    if [ "$CURRENT_SHELL" != "zsh" ]; then
        ZSH_PATH=$(which zsh)
        if chsh -s "$ZSH_PATH"; then
            echo "✅ デフォルトのシェルを zsh ($ZSH_PATH) に変更しました。"
        else
            echo "❌ デフォルトのシェルの変更に失敗しました。管理者権限が必要な場合があります。"
        fi
    else
        echo "✅ デフォルトのシェルは既に zsh です。"
    fi
else
    echo "CI環境ではデフォルトシェルの変更をスキップします。"
fi

# デフォルトのシェルが bash なら .bashrc を読み込み、zsh なら .zshrc を読み込むように設定
if [ "$SHELL" == "/bin/bash" ]; then
    echo "✅ デフォルトのシェルが bash です。.bashrc を読み込むように設定します。"
    echo "source ~/.bashrc" >> "$HOME/.bash_profile"
elif [ "$SHELL" == "/bin/zsh" ]; then
    echo "✅ デフォルトのシェルが zsh です。.zshrc を読み込むように設定します。"
    echo "source ~/.zshrc" >> "$HOME/.zshrc"
fi

# bat
install_if_missing "bat" "brew install bat"

# fzf
install_if_missing "fzf" "brew install fzf"

# eza
install_if_missing "eza" "brew install eza"

# fd
install_if_missing "fd" "brew install fd"

# aws cli
if ! command -v aws &> /dev/null; then
    echo "AWS CLI がインストールされていません。インストールを試みます。"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        brew install awscli
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install awscli
    fi

    if ! command -v aws &> /dev/null; then
        echo "❌ AWS CLI のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ AWS CLI のインストールが完了しました。"
    fi
else
    echo "✅ AWS CLI は既にインストールされています。"
fi
echo "aws --version: $(aws --version)"

# aws-vault
if ! command -v aws-vault &> /dev/null; then
    echo "aws-vault がインストールされていません。インストールを試みます。"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        brew install aws-vault
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install --cask aws-vault
    else
        echo "❌ サポートされていないOSです。aws-vault のインストールをスキップします。"
    fi

    if ! command -v aws-vault &> /dev/null; then
        echo "❌ aws-vault のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ aws-vault のインストールが完了しました。"
    fi
else
    echo "✅ aws-vault は既にインストールされています。"
fi

# jq
install_if_missing "jq" "brew install jq"

# gh (GitHub CLI)
install_if_missing "gh" "brew install gh"

# direnv
install_if_missing "direnv" "brew install direnv"
eval "$(direnv hook zsh)"

# direnv の初期化（dotfiles で管理されている前提）
# eval "$(direnv hook zsh)" は .zshrc に含まれている前提

# starship
install_if_missing "starship" "brew install starship"

# anyenv
install_if_missing "anyenv" "brew install anyenv"
git clone https://github.com/anyenv/anyenv ~/.anyenv
anyenv install --force-init
anyenv install -l
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

# シェルに anyenv のパスを追加（dotfiles で管理されている前提）
# eval "$(anyenv init -)" は .bashrc や .zshrc に含まれている前提

# **env のインストール
ENVS=("nodenv" "pyenv" "tfenv")

for env in "${ENVS[@]}"; do
    if [ ! -d "$HOME/.anyenv/envs/$env" ]; then
        echo "$env をインストールします..."
        anyenv install "$env"
    else
        echo "✅ $env は既にインストールされています。"
    fi
    eval "$(anyenv init -)"
    $env --version
done

# Visual Studio Code
echo "Visual Studio Code をインストールします..."
if ! command -v code &> /dev/null; then
    echo "Visual Studio Code がインストールされていません。インストールを試みます。"　
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

    if ! command -v code &> /dev/null; then
        echo "❌ Visual Studio Code のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ Visual Studio Code のインストールが完了しました。"
    fi
else
    echo "✅ Visual Studio Code は既にインストールされています。"
fi

# Hyper.js
echo "Hyper.js をインストールします..."
if ! command -v hyper &> /dev/null; then
    echo "Hyper.js がインストールされていません。インストールを試みます。"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            # 依存パッケージのインストール
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y libnotify4
            # Hyper.js のインストール
            DL_PATH="$HOME/Downloads"
            wget -P $DL_PATH https://releases.hyper.is/download/deb
            $SUDO dpkg -i "${DL_PATH}/deb"
            rm -rf "${DL_PATH}/deb"
        else
            $SUDO snap install hyper --classic
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install --cask hyper
    fi

    if ! command -v hyper &> /dev/null; then
        echo "❌ Hyper.js のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ Hyper.js のインストールが完了しました。"
    fi
else
    echo "✅ Hyper.js は既にインストールされています。"
fi

# Rancher Desktop
echo "Rancher Desktop をインストールします..."
if ! command -v rancher-desktop &> /dev/null; then
    if [[ "$OS_TYPE" == "Linux" ]]; then
        echo "Rancher Desktop がインストールされていません。インストールを試みます。"
        # Debian/Ubuntu 系の場合
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            curl -fsSL https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/Release.key | $SUDO gpg --dearmor -o /usr/share/keyrings/rancher-desktop-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/rancher-desktop-keyring.gpg] https://download.opensuse.org/repositories/isv:/Rancher:/stable/deb/ /" | $SUDO tee /etc/apt/sources.list.d/rancher-desktop.list
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y rancher-desktop
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            $SUDO curl -fsSL https://download.opensuse.org/repositories/isv:Rancher:stable/rpm.repo -o /etc/yum.repos.d/rancher-desktop.repo
            $SUDO yum install -y rancher-desktop
        fi

        if ! command -v rancher-desktop &> /dev/null; then
            echo "❌ Rancher Desktop のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "✅ Rancher Desktop のインストールが完了しました。"
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install --cask rancher
    fi
else
    echo "✅ Rancher Desktop は既にインストールされています。"
fi

# Google Chrome
echo "Google Chrome をインストールします..."
if ! command -v google-chrome &> /dev/null; then
    echo "Google Chrome がインストールされていません。インストールを試みます。"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | $SUDO gpg --dearmor -o /usr/share/keyrings/google-linux-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/google-linux-keyring.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | $SUDO tee /etc/apt/sources.list.d/google-chrome.list
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y google-chrome-stable
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            $SUDO sh -c 'echo -e "[google-chrome]\nname=Google Chrome\nbaseurl=http://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo'
            $SUDO yum check-update
            $SUDO yum install -y google-chrome-stable
        fi

        if ! command -v google-chrome &> /dev/null; then
            echo "❌ Google Chrome のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "✅ Google Chrome のインストールが完了しました。"
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install --cask google-chrome
        if [ ! -d "/Applications/Google Chrome.app" ]; then
            echo "❌ Google Chrome のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "✅ Google Chrome のインストールが完了しました。"
        fi
    else
        echo "❌ サポートされていないOSです。Google Chrome のインストールをスキップします。"
    fi
else
    echo "✅ Google Chrome は既にインストールされています。"
fi

# Brave
echo "Brave ブラウザをインストールします..."
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # Brave の GPG キーを追加
        $SUDO curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
            https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg

        # Brave のリポジトリを追加
        echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] \
        https://brave-browser-apt-release.s3.brave.com/ stable main" | $SUDO tee /etc/apt/sources.list.d/brave-browser-release.list

        # パッケージリストを更新
        $SUDO $PACKAGE_MANAGER update

        # Brave ブラウザをインストール
        $SUDO $PACKAGE_MANAGER install -y brave-browser
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        $SUDO dnf install dnf-plugins-core
        $SUDO dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
        $SUDO rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
        $SUDO dnf install -y brave-browser
    else
        echo "❌ Brave のインストール方法が不明です。手動でインストールしてください。"
    fi

    if ! command -v brave-browser &> /dev/null; then
        echo "❌ Brave ブラウザのインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ Brave ブラウザのインストールが完了しました。"
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install --cask brave-browser
else
    echo "❌ サポートされていないOSです。Brave のインストールをスキップします。"
fi
echo "brave-browser version: $(brave-browser --version)"

# 1Password
echo "1Password をインストールします..."
if ! command -v 1password &> /dev/null; then
    echo "1Password がインストールされていません。インストールを試みます。"
    if [[ "$OS_TYPE" == "Linux" ]]; then
        if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | $SUDO apt-key add -
            echo 'deb [arch=amd64] https://downloads.1password.com/linux/debian/amd64 stable main' | $SUDO tee /etc/apt/sources.list.d/1password.list
            $SUDO $PACKAGE_MANAGER update
            $SUDO $PACKAGE_MANAGER install -y 1password
        elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
            curl -sS https://downloads.1password.com/linux/keys/1password.asc | $SUDO rpm --import -
            $SUDO sh -c 'echo -e "[1password]\nname=1Password\nbaseurl=https://downloads.1password.com/linux/rpm\nenabled=1\ngpgcheck=1\ngpgkey=https://downloads.1password.com/linux/keys/1password.asc" > /etc/yum.repos.d/1password.repo'
            $SUDO yum check-update
            $SUDO yum install -y 1password
        fi

        if ! command -v 1password &> /dev/null; then
            echo "❌ 1Password のインストールに失敗しました。手動でインストールしてください。"
            exit 1
        else
            echo "✅ 1Password のインストールが完了しました。"
        fi
    elif [[ "$OS_TYPE" == "Darwin" ]]; then
        brew install --cask 1password
    else
        echo "❌ サポートされていないOSです。1Password のインストールをスキップします。"
    fi
else
    echo "✅ 1Password は既にインストールされています。"
fi
echo "1password version: $(1password --version)"

# HackGenNerd Font
echo "HackGenNerd Font をインストールします..."
if [[ "$OS_TYPE" == "Linux" ]]; then
    if [[ "$PACKAGE_MANAGER" == "apt" || "$PACKAGE_MANAGER" == "apt-get" ]]; then
        # バージョン指定
        HACKGEN_VERSION="2.9.0"
        DL_PATH="$HOME/Downloads"

        # CI のときは事前にダウンロードしてキャッシュしてるのでスキップ
        if [ "$CI" == "true" ]; then
            echo "CI環境で実行されているため、ダウンロードをスキップします。"
        else
            # HackGen_NF のダウンロードとインストール
            wget -P "$DL_PATH" "https://github.com/yuru7/HackGen/releases/download/v${HACKGEN_VERSION}/HackGen_NF_v${HACKGEN_VERSION}.zip"
        fi
        unzip -o "${DL_PATH}/HackGen_NF_v${HACKGEN_VERSION}.zip" -d "$DL_PATH"
        # ユーザーにインストール
        mkdir -p "$HOME/.local/share/fonts"
        cp -r "${DL_PATH}/HackGen_NF_v${HACKGEN_VERSION}/"* "$HOME/.local/share/fonts/"

        if [ "$CI" != "true" ]; then
            # インストーラとディレクトリを削除
            rm -rf "${DL_PATH}/HackGen_NF_v${HACKGEN_VERSION}"
            rm -rf "${DL_PATH}/HackGen_v${HACKGEN_VERSION}.zip"
        fi

        # HackGen のダウンロードとインストール
        wget -P "$DL_PATH" "https://github.com/yuru7/HackGen/releases/download/v${HACKGEN_VERSION}/HackGen_v${HACKGEN_VERSION}.zip"
        unzip -o "${DL_PATH}/HackGen_v${HACKGEN_VERSION}.zip" -d  "$DL_PATH"
        # ユーザーにインストール
        cp -r "${DL_PATH}/HackGen_v${HACKGEN_VERSION}/"* "$HOME/.local/share/fonts/"
        # インストーラとディレクトリを削除
        rm -rf "${DL_PATH}/HackGen_v${HACKGEN_VERSION}"
        rm -rf "${DL_PATH}/HackGen_v${HACKGEN_VERSION}.zip"

        # フォントのキャッシュを更新
        fc-cache -vf
        # フォントのインストール確認
        if fc-list | grep -i "HackGen"; then
            echo "✅ HackGenNerd Font が正常にインストールされました。"
        else
            echo "❌ HackGenNerd Font のインストールに失敗しました。"
            exit 1
        fi
    elif [[ "$PACKAGE_MANAGER" == "yum" ]]; then
        $SUDO yum install -y
    fi
elif [[ "$OS_TYPE" == "Darwin" ]]; then
    brew install --cask font-hackgen-nerd

    if [ "$?" -eq 0 ]; then
        echo "✅ HackGenNerd Font が正常にインストールされました。"
    else
        echo "❌ HackGenNerd Font のインストールに失敗しました。"
        exit 1
    fi
fi
echo "HackGenNerd Font のインストールが完了しました。"

# deskpad のインストール ※macOS のみ
if [[ "$OS_TYPE" == "Darwin" ]]; then
    if ! command -v deskpad &> /dev/null; then
        brew install deskpad
    fi

    # アプリの存在有無でインストールされたかどうかをチェック
    if [ ! -e /Applications/DeskPad.app ]; then
        echo "❌ deskpad のインストールに失敗しました。手動でインストールしてください。"
        exit 1
    else
        echo "✅ deskpad のインストールが完了しました。"
    fi
fi

echo "セットアップが完了しました！"

if [ "$CI" == "true" ]; then
    echo "CI環境で実行されているため、再起動は必要ありません。"
    exit 0
else
    # 再起動の提案
    echo "変更を反映するために、ログアウトして再度ログインするか、システムを再起動することをおすすめします。"
fi

# 処理完了
exit 0
