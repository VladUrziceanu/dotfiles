#!/usr/bin/env bash

set -e -u -o pipefail

execute() {
  cmd=$1
  msg=$2

  eval "${cmd}"
  if [[ $? -eq 0 ]]; then
    # Print output in green.
    printf "\e[0;32m  [✔] %s\e[0m\n" "${msg}"
  else
    # Print output in red.
    printf "\e[0;31m  [✖] %s\e[0m\n" "${msg}"
    exit 1
  fi
}


install_omz() {
  ZSH=${HOME}/.oh-my-zsh
  ZSH_CUSTOM="${ZSH_CUSTOM:-${ZSH}/custom}"

  # Clone or update Oh My Zsh.
  if [[ ! -d "${ZSH}" ]]; then
    git clone --quiet --filter=blob:none https://github.com/robbyrussell/oh-my-zsh "${ZSH}"
  else
    git -C "${ZSH}" pull --quiet
  fi

  # Install or update custom oh-my-zsh plugins.
  CUSTOM_PLUGIN_REPOS=(
    "https://github.com/Aloxaf/fzf-tab"
    "https://github.com/zdharma-continuum/fast-syntax-highlighting"
    "https://github.com/zsh-users/zsh-autosuggestions"
  )
  for REPO_URL in "${CUSTOM_PLUGIN_REPOS[@]}"; do
    PLUGIN_PATH="${ZSH_CUSTOM}/plugins/${REPO_URL##*/}"
    if [[ ! -d "${PLUGIN_PATH}" ]]; then
      git clone --quiet --filter=blob:none "${REPO_URL}" "${PLUGIN_PATH}"
    else
      git -C "${PLUGIN_PATH}" pull --quiet
    fi
  done
}

install_tmux_themepack() {
  TMUX_THEMEPACK=${HOME}/.tmux-themepack

  if [[ ! -d "${TMUX_THEMEPACK}" ]]; then
    git clone --quiet --filter=blob:none https://github.com/jimeh/tmux-themepack.git "${TMUX_THEMEPACK}"
  else
    git -C "${TMUX_THEMEPACK}" pull --quiet
  fi
}

install_gdb_dashboard() {
  GDBINIT=${HOME}/.gdbinit

  if [[ ! -e "${GDBINIT}" ]]; then
    if whence wget &>/dev/null; then
      wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
    elif whence curl &>/dev/null; then
      curl -L -o "${GDBINIT}" https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
    else
      printf "\e[0;31m  [✖] %s\e[0m\n" "Please install wget or curl to download .gdbinit."
    fi
  fi
}

link_file() {
  local source=$1
  local target=$2

  # We've already symlinked, do nothing.
  if [[ "$(readlink "${target}")" == "${source}" ]]; then
    return
  fi

  # If the target location exists and it's not our target symlink, we create a backup.
  if [[ -e "${target}" ]]; then
    epoch=$(date +%s)
    execute "mv ${target} ${target}.${epoch}.bak" "Backing up ${target} → ${target}.${epoch}.bak"
  fi

  # Symlink the dotfile.
  execute "ln -fs ${source} ${target}" "Linking ${target} → ${source}"
}

main() {
  install_omz
  install_tmux_themepack
  install_gdb_dashboard

  FILES_TO_SYMLINK=($(find configs -mindepth 1 -maxdepth 1 -type f))
  for dotfile in "${FILES_TO_SYMLINK[@]}"; do
    sourceFile="$(pwd)/${dotfile}"
    targetFile="${HOME}/.$(basename "${dotfile}")"

    link_file "$sourceFile" "$targetFile"
  done
}

main
