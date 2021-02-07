eval $(/opt/homebrew/bin/brew shellenv)
export PATH="$HOMEBREW_PREFIX/opt/icu4c/bin:$HOMEBREW_PREFIX/opt/icu4c/sbin:$PATH"
export PATH="$HOME/Library/Python/3.8/bin:/usr/local/bin:$HOME/bin:$PATH"
alias python=python3
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
export VIRTUALENVWRAPPER_HOOK_DIR=$HOME/.virtualenvs
source $HOME/Library/Python/3.8/bin/virtualenvwrapper.sh
workon venv
