# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="agnoster"
ENABLE_CORRECTION="true"

# История
export HISTFILE="$HOME/.zsh_history"
export HISTSIZE=100000
export SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
# Подгрузить историю при запуске, если есть
[[ -f "$HISTFILE" ]] && fc -R "$HISTFILE"

# Плагины
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  docker
  docker-compose
  emacs
  github
  node
  npm
  postgres
  sudo
  systemd
  symfony
  ubuntu
  vscode
)

if [ ! -d "$ZSH" ]; then
  git clone https://github.com/ohmyzsh/ohmyzsh.git "$ZSH"
fi

# Ensure external plugins exist
for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  target="$ZSH/custom/plugins/$plugin"
  if [ ! -d "$target" ]; then
    case "$plugin" in
      zsh-autosuggestions)
        git clone https://github.com/zsh-users/zsh-autosuggestions "$target"
        ;;
      zsh-syntax-highlighting)
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$target"
        ;;
    esac
  fi
done

source "$ZSH/oh-my-zsh.sh"

# Настройки autosuggestions (опционально подстройте цвет)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# BEGIN SNIPPET: Platform.sh CLI configuration
HOME=${HOME:-'/home/askar'}
export PATH="$HOME/.platformsh/bin":"$PATH"
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
# pnpm
export PNPM_HOME="/home/askar/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
if [ -f "$HOME/.platformsh/shell-config.rc" ]; then . "$HOME/.platformsh/shell-config.rc"; fi
# END SNIPPET
