################################################################################
# Path variable
################################################################################

fish_add_path $HOME/bin
fish_add_path $HOME/.local/bin

################################################################################
# Tmux setup
################################################################################

# Use 256 color for tmux.
alias tmux="TERM=screen-256color-bce tmux"
# Attempt to take over existing sessions before creating a new tmux session.
function t
  tmux -u new -ADs {$argv[1]:-tmux}
end
if not set -q TMUX
  # Switch to xterm if we're in a tmux session.
  set -x TERM "xterm-256color"
end

################################################################################
# Environment setup
################################################################################

set -x HISTSIZE 10000
set -x SAVEHIST 10000

if status --is-interactive
    if command -v nvim >/dev/null
        set -gx EDITOR nvim
        alias vim nvim
    else if command -v vim >/dev/null
        set -gx EDITOR vim
    end
end


################################################################################
# Aliases
################################################################################

alias csrefresh="find ./ -name '*.c' -o -name '*.h' -o -name '*.cc' -o -name '*.cpp' > cscope.files"

if command -v eza >/dev/null
  alias ls "eza"
end

if command -v batcat >/dev/null
  alias cat "batcat"
end

################################################################################
# Shell tools setup
################################################################################

# fzf setup
if command -v fzf >/dev/null
  source (fzf --fish | psub)
  # Display source tree and file preview for ALT-C.
  set -g FZF_ALT_C_OPTS "--preview '(eza --tree --icons --level 3 --color=always --group-directories-first {} || tree -C {}) | head -200'"

  # Bind alt-j/k/d/u to moving the preview window for fzf.
  set -g FZF_DEFAULT_OPTS "--bind alt-k:preview-up,alt-j:preview-down,alt-u:preview-page-up,alt-d:preview-page-down"

  # Show previews for files and directories.
  set -g FZF_CTRL_T_OPTS "--preview '(bat --style=numbers --color=always {} || cat {}) 2> /dev/null | head -200'"
end

if command -v zoxide >/dev/null
  zoxide init --cmd cd fish | source
end

if command -v fd >/dev/null
  set -g FZF_DEFAULT_COMMAND 'fd --type f --follow --hidden'
  set -g FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
  set -g FZF_ALT_C_COMMAND='fd --type d --color never'
end

################################################################################
# Fish plugin management
################################################################################

if command -v fisher >/dev/null
  fisher install PatrickF1/fzf.fish
  fisher install gazorby/fish-foreign-env
end

################################################################################

# Source local fish config.
if test -f ~/.config/fish/config.local.fish
  source ~/.config/fish/config.local.fish
end
