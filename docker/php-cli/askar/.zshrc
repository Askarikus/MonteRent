export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="agnoster"

ENABLE_CORRECTION="true"

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

source $ZSH/oh-my-zsh.sh

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

# Generated for envman. Do not edit.
[ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"

# BEGIN SNIPPET: Platform.sh CLI configuration
HOME=${HOME:-'/home/askar'}
export PATH="$HOME/"'.platformsh/bin':"$PATH"
export DOTNET_ROOT=$HOME/.dotnet
export PATH=$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
# pnpm
export PNPM_HOME="/home/askar/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end
if [ -f "$HOME/"'.platformsh/shell-config.rc' ]; then . "$HOME/"'.platformsh/shell-config.rc'; fi # END SNIPPET
