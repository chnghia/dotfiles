#!/usr/bin/env bash

COLOR_GRAY="\033[1;38;5;243m"
COLOR_BLUE="\033[1;34m"
COLOR_GREEN="\033[1;32m"
COLOR_RED="\033[1;31m"
COLOR_PURPLE="\033[1;35m"
COLOR_YELLOW="\033[1;33m"
COLOR_NONE="\033[0m"

title() {
    echo -e "\n${COLOR_PURPLE}$1${COLOR_NONE}"
    echo -e "${COLOR_GRAY}==============================${COLOR_NONE}\n"
}

success() {
    echo -e "${COLOR_GREEN}$1${COLOR_NONE}"
}

setup_symlinks() {
  title "Creating symlinks"
  cd $HOME
  ln -s .dotfiles/aliases .aliases
  ln -s .dotfiles/SpaceVim.d .SpaceVim.d
  ln -s .dotfiles/p10k.zsh .p10k.zsh
  ln -s .dotfiles/SpaceVim .SpaceVim
  ln -s .dotfiles/SpaceVim .vim
  ln -s .dotfiles/zprofile .zprofile
  ln -s .dotfiles/zshrc .zshrc
  ln -s .dotfiles/zshrc.local .zshrc.local
}

setup_symlinks

echo -e
success "Done."