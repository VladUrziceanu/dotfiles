################################################################################
# Path variable
################################################################################

fish_add_path $HOME/bin
fish_add_path $HOME/.local/bin

################################################################################
# Tmux setup
################################################################################

# Use 256 color for tmux.
alias tmux="TERM=screen-256color-bce command tmux"
# Attempt to take over existing sessions before creating a new tmux session.
function t
  set -l session_name
  if [ (count $argv) -gt 0 ]
    set session_name $argv[1]
  else
    set session_name "tmux"
  end
  tmux -u new -ADs $session_name
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

if command -v brew >/dev/null
  alias b="brew"
end

################################################################################
# Colored man pages
################################################################################

if command -v bat >/dev/null
    set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
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

  function fzf --wraps=fzf --description="Use fzf-tmux if in tmux session"
    if set --query TMUX
      fzf-tmux $argv
    else
      command fzf $argv
    end
  end
end

if command -v zoxide >/dev/null
  zoxide init --cmd cd fish | source
end

if command -v fd >/dev/null
  set -g FZF_DEFAULT_COMMAND 'fd --type f --follow --hidden'
  set -g FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
  set -g FZF_ALT_C_COMMAND "fd --type d --color never"
end

################################################################################

# Source local fish config.
if test -f ~/.config/fish/config.local.fish
  source ~/.config/fish/config.local.fish
end
