#!/bin/bash

# ------------------------------------------------------------------------------
# brew
# ------------------------------------------------------------------------------
detect_os() {
  if [ "$(uname)" == "Darwin" ]; then
    PLATFORM=mac
  elif [ "$(uname -s)" == "MINGW" ]; then
    PLATFORM=windows
  elif [ "$(uname -s)" == "Linux" ]; then
    PLATFORM=linux
  else
    PLATFORM="Unknown OS"
    abort "Your platform ($(uname -a)) is not supported."
  fi
}

is_exists() {
  which "$1" >/dev/null 2>&1
  return $?
}

is_linux() {
  if [ "$PLATFORM" == 'linux' ]; then
    return 0
  else
    return 1
  fi
}

is_mac() {
  if [ "$PLATFORM" == 'mac' ]; then
    return 0
  else
    return 1
  fi
}

if [[ $(command -v brew) ]]; then
  if is_linux; then
    if [ -r "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh" ]; then
      # shellcheck source=/dev/null
      . "/home/linuxbrew/.linuxbrew/etc/profile.d/bash_completion.sh"
    fi
  fi

  if is_mac; then
    if [ -r "/opt/homebrew/etc/profile.d/bash_completion.sh" ]; then
      # shellcheck source=/dev/null
      . "/opt/homebrew/etc/profile.d/bash_completion.sh"
    fi
  fi
fi

# ------------------------------------------------------------------------------
# asdf
# ------------------------------------------------------------------------------
if [[ $(command -v brew) ]]; then
  # see https://asdf-vm.com/guide/getting-started.html#_2-download-asdf
  # Bash & Homebrew (macOS)

  # shellcheck source=/dev/null
  . "$(brew --prefix asdf)/asdf.sh"
  # shellcheck source=/dev/null
  . "$(brew --prefix asdf)/etc/bash_completion.d/asdf.bash"
fi

# ------------------------------------------------------------------------------
# VS Code
# ------------------------------------------------------------------------------

# Remote Containers >> SSH
if [ -z "$SSH_AUTH_SOCK" ]; then
  # Check for a currently running instance of the agent
  RUNNING_AGENT="$(pgrep -f 'ssh-agent -s' | wc -l | tr -d '[:space:]')"
  if [ "$RUNNING_AGENT" = "0" ]; then
    # Launch a new instance of the agent
    ssh-agent -s &> "$HOME/.ssh/ssh-agent"
  fi
  eval "cat $HOME/.ssh/ssh-agent"
fi

# anyenv
eval "$(anyenv init -)"
