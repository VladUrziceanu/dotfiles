#!/usr/bin/env bash

set -e -u -o pipefail

# ======================================================================================================================
#  ____        _   _
# |  _ \  ___ | |_| |_ ___ _ __
# | | | |/ _ \| __| __/ _ \ '__|
# | |_| | (_) | |_| ||  __/ |
# |____/ \___/ \__|
#
# ======================================================================================================================

# Define a function to get the absolute path of the script.
get_script_dir() {
  SOURCE="${BASH_SOURCE[0]}"
  while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symbollink, we need to resolve it relative to the path where the symlink file was located
  done
  echo "$(cd -P "$(dirname "$SOURCE")" && pwd)"
}

SCRIPT_DIR=$(get_script_dir)
# Go to the script's directory.
cd "${SCRIPT_DIR}"

# ======================================================================================================================
#  ____
# / ___| ___ _ __   ___ _ __
# \___ \/ _ \ '_ \ / _ \ '__|
#  ___) |  __/ | | |  __/ |
# |____/ \___|_| |_|\___|_|
#
# ======================================================================================================================

# Define color codes for output messages.
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'

# Print a message with a specified color.
# Arguments:
#   $1: Color code
#   $2: Message string
color_print() {
  local color="$1"
  local msg="$2"
  printf "%b%s%b\n" "${color}" "${msg}" "${C_RESET}"
}

# Print an error message and exit.
# Arguments:
#   $1: Error message string
error() {
  color_print "${C_RED}" "  [✖] $1"
  exit 1
}

# Print a success message.
# Arguments:
#   $1: Success message string
success() {
  color_print "${C_GREEN}" "  [✔] $1"
}

# Print a warning message.
# Arguments:
#   $1: Warning message string
warn() {
  color_print "${C_YELLOW}" "  [!] $1"
}

# Print an informational message.
# Arguments:
#   $1: Informational message string
info() {
  color_print "${C_BLUE}" "› $1"
}

# Execute a command and print a message.
# Arguments:
#   $1: Command to execute
#   $2: Message to print
execute() {
  local cmd="$1"
  local msg="$2"

  info "${msg}"
  if eval "${cmd}"; then
    success "${msg}"
  else
    error "Failed to execute: ${cmd}"
  fi
}

# ======================================================================================================================
#  ____  _             _
# / ___|| |_ __ _ _ __| |_
# \___ \| __/ _` | '__| __|
#  ___) | || (_| | |  | |_
# |____/ \__\__,_|_|   \__|
#
# ======================================================================================================================

# Check if a command is available.
# Arguments:
#   $1: Command name
command_exists() {
  command -v "$1" &>/dev/null
}

# Detect the operating system.
# Returns:
#   "macos", "linux", or "unknown"
detect_os() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux) echo "linux" ;;
    *) echo "unknown" ;;
  esac
}

# ======================================================================================================================
#  _   _      _
# | \ | | ___| |___  ___  _ __
# |  \| |/ _ \ __\ \/ / | '_ \
# | |\  |  __/ |_ >  <| | |_) |
# |_| \_|\___|\__/_/\_\_| .__/
#                       |_|
# ======================================================================================================================

# Install dependencies using Homebrew (macOS).
install_brew_dependencies() {
  if ! command_exists brew; then
    error "Homebrew not found. Please install it first from https://brew.sh/"
  fi

  local brew_packages=(
    eza
    bat
    zoxide
    fd
    neovim
    tmux
    wget
    fzf
    fish
  )

  info "Checking Homebrew dependencies..."
  local to_install=()
  for pkg in "${brew_packages[@]}"; do
    if ! brew list --formula | grep -q "^${pkg}\\$"; then
      to_install+=("${pkg}")
    else
      success "${pkg} is already installed."
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    execute "brew install ${to_install[*]}" "Installing ${to_install[*]}..."
  else
    success "All Homebrew dependencies are already installed."
  fi

  # Install fzf key bindings and fuzzy completion
  if ! [ -f ~/.fzf.zsh ]; then
    info "Installing fzf key bindings and fuzzy completion..."
  "$(brew --prefix)/opt/fzf/install" --bin --key-bindings --completion --no-update-rc
  fi
}

# Install dependencies using APT (Debian/Ubuntu).
install_apt_dependencies() {
  if ! command_exists apt-get; then
    error "apt-get not found. This script currently only supports Debian-based distributions."
  fi

  # On linux, bat is batcat, fd is fd-find. eza is not in default repos.
  local apt_packages=(
    git
    bat
    fd-find
    tmux
    wget
    curl
    xclip
    xdotool
    gdb
    zsh
    fish
  )

  info "Checking APT dependencies..."
  # Update package lists if they haven't been updated in the last 24 hours.
  local last_update
  last_update=$(stat -c %Y /var/cache/apt/pkgcache.bin 2>/dev/null || echo 0)
  local now
  now=$(date +%s)
  if [ $((now - last_update)) -gt 86400 ]; then
    execute "sudo apt-get update" "Updating package lists"
  else
    info "Package lists are up-to-date."
  fi

  local to_install=()
  for pkg in "${apt_packages[@]}"; do
    if ! dpkg -s "${pkg}" &>/dev/null; then
      to_install+=("${pkg}")
    else
      success "${pkg} is already installed."
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    info "This may require sudo password."
    execute "sudo apt-get install -y ${to_install[*]}" "Installing ${to_install[*]}..."
  else
    success "All APT dependencies are already installed."
  fi

  # Install eza separately as it's not in default repos
  if ! command_exists eza; then
    warn "eza not found. Please install it manually. See https://github.com/eza-community/eza/blob/main/INSTALL.md"
  fi
}

# Install the latest version of Neovim on Linux.
install_neovim_linux() {
  if command_exists nvim; then
    success "Neovim is already installed."
    return
  fi

  info "Installing latest Neovim on Linux..."
  execute "mkdir -p ${HOME}/.local/bin" "Creating .local/bin directory..."

  local arch
  arch=$(dpkg --print-architecture)
  local nvim_url=""
  local nvim_archive=""
  local nvim_dir=""

  case "${arch}" in
    "amd64")
      nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
      nvim_archive="/tmp/nvim-linux64.tar.gz"
      nvim_dir="/tmp/nvim-linux64"
      ;;
    "arm64")
      nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-arm64.tar.gz"
      nvim_archive="/tmp/nvim-linux-arm64.tar.gz"
      nvim_dir="/tmp/nvim-linux-arm64"
      ;;
    *)
      warn "Unsupported Linux architecture for Neovim auto-install: ${arch}. Please install it manually."
      return
      ;;
  esac

  execute "curl -L ${nvim_url} -o ${nvim_archive}" "Downloading nvim for ${arch}..."
  execute "tar xzf ${nvim_archive} -C /tmp" "Extracting nvim..."
  execute "mv ${nvim_dir}/bin/nvim ${HOME}/.local/bin/" "Installing nvim..."
  execute "rm -rf ${nvim_dir} ${nvim_archive}" "Cleaning up nvim install..."
  success "Neovim installed successfully."
}

# ======================================================================================================================
#   ____             __ _
#  / ___|___  _ __  / _(_) __ _
# | |   / _ \| '_ \| |_| |/ _` |
# | |__| (_) | | | |  _| | (_| |
#  \____\___/|_| |_|_| |_|\__, |
#                         |___/
# ======================================================================================================================

# Clone or update a Git repository.
# Arguments:
#   $1: Repository URL
#   $2: Target directory
#   $3: Repository name for messages
git_clone_or_update() {
  local repo_url="$1"
  local target_dir="$2"
  local repo_name="$3"

  if [ ! -d "${target_dir}" ]; then
    execute "git clone --quiet --filter=blob:none ${repo_url} ${target_dir}" "Cloning ${repo_name}..."
  else
    info "Updating ${repo_name}..."
    if git -C "${target_dir}" pull --quiet; then
      success "${repo_name} is up-to-date."
    else
      error "Failed to update ${repo_name}."
    fi
  fi
}

# Install Oh My Zsh and custom plugins.
install_omz() {
  info "Installing Oh My Zsh and plugins..."
  local omz_dir="${HOME}/.oh-my-zsh"
  local zsh_custom="${omz_dir}/custom"

  git_clone_or_update "https://github.com/robbyrussell/oh-my-zsh" "${omz_dir}" "Oh My Zsh"

  local custom_plugin_repos=(
    "https://github.com/Aloxaf/fzf-tab"
    "https://github.com/zdharma-continuum/fast-syntax-highlighting"
    "https://github.com/zsh-users/zsh-autosuggestions"
  )
  for repo_url in "${custom_plugin_repos[@]}"; do
    local plugin_name
    plugin_name="${repo_url##*/}"
    local plugin_path="${zsh_custom}/plugins/${plugin_name}"
    git_clone_or_update "${repo_url}" "${plugin_path}" "${plugin_name}"
  done
}

# Install Tmux Themepack.
install_tmux_themepack() {
  info "Installing Tmux Themepack..."
  git_clone_or_update "https://github.com/jimeh/tmux-themepack.git" "${HOME}/.tmux-themepack" "Tmux Themepack"
}

# Install GDB Dashboard.
install_gdb_dashboard() {
  local gdbinit="${HOME}/.gdbinit"
  if [ -f "${gdbinit}" ]; then
    success "GDB Dashboard already installed."
    return
  fi

  info "Installing GDB Dashboard..."
  if command_exists wget; then
    execute "wget -q -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit" "Downloading .gdbinit with wget"
  elif command_exists curl; then
    execute "curl -sL -o ${gdbinit} https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit" "Downloading .gdbinit with curl"
  else
    error "Please install wget or curl to download .gdbinit."
  fi
}

# Install NvChad configuration.
install_nvim_config() {
  info "Installing NvChad config..."
  git_clone_or_update "https://github.com/VladUrziceanu/NvChad-config" "${HOME}/.config/nvim" "NvChad config"
}

# Install fzf from source.
install_fzf_from_source() {
  info "Installing fzf from source..."
  git_clone_or_update "https://github.com/junegunn/fzf.git" "${HOME}/.fzf" "fzf"
  # The --all flag installs key bindings and fuzzy completion.
  # --no-update-rc prevents it from modifying shell rc files directly.
  execute "${HOME}/.fzf/install --all --no-update-rc" "Installing fzf shell integration"
  success "fzf installed from source."
  warn "Add 'source ~/.fzf.zsh' to your .zshrc to enable fzf."
}

# Install fisher package manager for fish shell.
install_fisher() {
  info "Installing fisher..."
  if fish -c "not type -q fisher"; then
    execute "fish -c 'curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher'" "Installing fisher..."
  fi
}

# Install fish plugins from the fish_plugins file.
install_fish_plugins() {
  info "Installing fish plugins..."
  execute "fish -c 'fisher update'" "Installing fisher plugins..."
}


# ======================================================================================================================
#  _            _
# | | ___   ___| | __
# | |/ _ \ / __| |/ /
# | | (_) | (__|   <
# |_|\___/ \___|_|\_\
#
# ======================================================================================================================

# Create a symlink, backing up the original file if it exists.
# Arguments:
#   $1: Source file
#   $2: Target file
link_file() {
  local source_file="$1"
  local target_file="$2"

  # If the target is already a symlink to the source, do nothing.
  if [ -L "${target_file}" ] && [ "$(readlink "${target_file}")" == "${source_file}" ]; then
    success "Symlink already exists: ${target_file} → ${source_file}"
    return
  fi

  # If the target exists and is not a symlink, create a backup.
  if [ -e "${target_file}" ] && [ ! -L "${target_file}" ]; then
    local backup_file="${target_file}.$(date +%s).bak"
    warn "Backing up existing file: ${target_file} → ${backup_file}"
    if ! mv "${target_file}" "${backup_file}"; then
      error "Failed to back up ${target_file}."
    fi
  fi

  # Create the symlink.
  info "Linking ${target_file} → ${source_file}"
  if ! ln -fs "${source_file}" "${target_file}"; then
    error "Failed to create symlink: ${target_file}"
  fi
  success "Successfully linked ${target_file} → ${source_file}"
}

# Create symlinks for all configuration files in the 'configs' directory.
create_symlinks() {
  info "Creating symlinks for dotfiles..."
  local configs_dir="${SCRIPT_DIR}/configs"

  # Find all files in the configs directory.
  local files_to_symlink
  files_to_symlink=($(find "${configs_dir}" -mindepth 1 -maxdepth 1 -type f))

  if [ ${#files_to_symlink[@]} -eq 0 ]; then
    warn "No files found to symlink in ${configs_dir}."
    return
  fi

  for source_path in "${files_to_symlink[@]}"; do
    local filename
    filename=$(basename "${source_path}")
    local target_path

    if [ "${filename}" == "config.fish" ]; then
      target_path="${HOME}/.config/fish/config.fish"
      execute "mkdir -p ${HOME}/.config/fish" "Creating fish config directory..."
    elif [ "${filename}" == "fish_plugins" ]; then
      target_path="${HOME}/.config/fish/fish_plugins"
      execute "mkdir -p ${HOME}/.config/fish" "Creating fish config directory..."
    else
      target_path="${HOME}/.${filename}"
    fi

    link_file "${source_path}" "${target_path}"
  done
}

# ======================================================================================================================
#  __  __
# |  \/  | __ _ _ __   __ _  __ _  ___
# | |\/| |/ _` | '_ \ / _` |/ _` |/ _ \
# | |  | | (_| | | | | (_| | (_| |  __/
# |_|  |_|\__,_|_| |_|\__,_|\__, |\___|
#                          |___/
# ======================================================================================================================

# Set the preferred shell based on user input.
# Arguments:
#   $1: The shell to set as preferred ("fish" or "zsh")
set_preferred_shell() {
  local shell_choice="$1"
  local prefer_fish_file="${HOME}/.prefer_fish"

  if [ "${shell_choice}" == "fish" ]; then
    info "Setting fish as the preferred shell."
    if ! touch "${prefer_fish_file}"; then
      error "Failed to create ${prefer_fish_file}."
    fi
    success "Fish is set as the preferred shell. It will be auto-launched from .zshrc."
  elif [ "${shell_choice}" == "zsh" ]; then
    info "Setting zsh as the preferred shell."
    if [ -f "${prefer_fish_file}" ]; then
      if ! rm "${prefer_fish_file}"; then
        error "Failed to remove ${prefer_fish_file}."
      fi
    fi
    success "Zsh is set as the preferred shell."
  else
    error "Invalid shell choice: ${shell_choice}. Please use 'fish' or 'zsh'."
  fi
}

main() {
  info "Starting dotfiles setup..."

  # Default values
  local preferred_shell=""

  # Parse command-line arguments
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      --fish)
        if [ -n "${preferred_shell}" ]; then error "Cannot specify both --fish and --zsh."; fi
        preferred_shell="fish"
        shift # past argument
        ;;
      --zsh)
        if [ -n "${preferred_shell}" ]; then error "Cannot specify both --fish and --zsh."; fi
        preferred_shell="zsh"
        shift # past argument
        ;;
      *) # unknown option
        error "Unknown option: $1"
        ;;
    esac
  done

  local os
  os=$(detect_os)

  case "${os}" in
    "macos")
      info "macOS detected."
      install_brew_dependencies
      ;;
    "linux")
      info "Linux detected."
      install_apt_dependencies
      install_neovim_linux
      install_fzf_from_source
      ;;
    *)
      error "Unsupported operating system: $(uname -s)"
      ;;
  esac

  install_omz
  install_tmux_themepack
  install_gdb_dashboard
  install_nvim_config
  install_fisher
  create_symlinks
  install_fish_plugins

  # Set the preferred shell if the user provided a flag
  if [ -n "${preferred_shell}" ]; then
    set_preferred_shell "${preferred_shell}"
  fi

  success "Dotfiles setup complete!"
  warn "Please restart your shell or source your .zshrc for changes to take effect."
}

main "$@"

