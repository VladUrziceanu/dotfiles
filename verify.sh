#!/usr/bin/env bash
set -e -u -o pipefail

# Add fzf and local bin to the PATH for this script
export PATH="${HOME}/.fzf/bin:${HOME}/.local/bin:${PATH}"

echo "--- Running Verification ---"

# Function to check for a file and its symlink target
check_symlink() {
  local file=$1
  local target=$2
  local full_target="/home/testuser/${target}"

  printf "  Checking symlink for %s..." "$file"
  if [[ ! -L "$file" ]]; then
    echo " FAIL: Not a symlink."
    exit 1
  fi

  if [[ "$(readlink "$file")" != "$full_target" ]]; then
    echo " FAIL: Incorrect target."
    exit 1
  fi
  echo " OK"
}

# Function to check if a command is available
check_command() {
  local cmd=$1
  printf "  Checking for command '%s'..." "$cmd"
  if ! command -v "$cmd" &>/dev/null; then
    echo " FAIL: Not found."
    exit 1
  fi
  echo " OK"
}

# 1. Verify Symlinks
echo "› Verifying configuration symlinks..."
check_symlink "/home/testuser/.zshrc" "configs/zshrc"
check_symlink "/home/testuser/.tmux.conf" "configs/tmux.conf"
check_symlink "/home/testuser/.gitconfig" "configs/gitconfig"
check_symlink "/home/testuser/.gitignore_global" "configs/gitignore_global"
check_symlink "/home/testuser/.config/fish/config.fish" "configs/config.fish"

# 2. Verify Dependencies
echo "› Verifying installed dependencies..."
check_command "zsh"
check_command "git"
check_command "fzf"
check_command "nvim"
check_command "tmux"
check_command "gdb"
check_command "xclip"
check_command "xdotool"
check_command "fish"

# 3. Verify Oh My Zsh installation
echo "› Verifying Oh My Zsh installation..."
if [[ ! -d "/home/testuser/.oh-my-zsh" ]]; then
    echo "  FAIL: .oh-my-zsh directory not found."
    exit 1
fi
echo "  OK"

# 4. Verify NvChad installation
echo "› Verifying NvChad installation..."
if [[ ! -d "/home/testuser/.config/nvim" ]]; then
    echo "  FAIL: NvChad config directory not found."
    exit 1
fi
echo "  OK"


echo "--- Verification Complete: All checks passed! ---"
