FPATH="$HOME/.config/zsh/completion:${FPATH}"

if ( type brew &>/dev/null )
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"

  autoload -Uz compinit
  compinit
fi

setopt EXTENDED_HISTORY
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt INC_APPEND_HISTORY
export HISTTIMEFORMAT="[%F %T] "

source $HOME/.env
source $HOME/.me

if [[ "$OR_APP_NAME" != "Aider" ]]; then
  eval "$(nodenv init -)"
  if command -v pyenv > /dev/null; then eval "$(pyenv init -)"; fi
  eval "$(rbenv init -)"

  # Source Cargo environment
  . "$HOME/.cargo/env"

  export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl@1.1)"
fi

eval "$(op completion zsh)"; compdef _op op

# Added by Pear Runtime, configures system with Pear CLI
export PATH="/Users/kaleblape/Library/Application Support/pear/bin":$PATH
