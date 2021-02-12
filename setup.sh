#!/usr/bin/env bash

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
