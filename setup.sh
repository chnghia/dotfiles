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

setup_homebrew() {
    title "Setting up Homebrew"

    if test ! "$(command -v brew)"; then
        info "Homebrew not installed. Installing."
        # Run as a login shell (non-interactive) so that the script doesn't pause for user input
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
    fi

    # install brew dependencies from Brewfile
    brew bundle

    # install fzf
    echo -e
    info "Installing fzf"
    "$(brew --prefix)"/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish
}

setup_macos() {
    title "Configuring macOS"
    if [[ "$(uname)" == "Darwin" ]]; then
        echo "show the ~/Library folder in Finder"
        chflags nohidden ~/Library

        echo "Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)"
        defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

        echo "Enable subpixel font rendering on non-Apple LCDs"
        defaults write NSGlobalDomain AppleFontSmoothing -int 2

        echo "Use current directory as default search scope in Finder"
        defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

        echo "Disable press-and-hold for keys in favor of key repeat"
        defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

        echo "Set a blazingly fast keyboard repeat rate"
        defaults write NSGlobalDomain KeyRepeat -int 1

        echo "Set a shorter Delay until key repeat"
        defaults write NSGlobalDomain InitialKeyRepeat -int 15

        echo "Enable tap to click (Trackpad)"
        defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
    else
        warning "macOS not detected. Skipping."
    fi
}

setup_symlinks() {
  title "Creating symlinks"
  cd $HOME
  ln -s .dotfiles/aliases $HOME/.aliases
  ln -s .dotfiles/SpaceVim.d $HOME/.SpaceVim.d
  ln -s .dotfiles/p10k.zsh $HOME/.p10k.zsh
  ln -s .dotfiles/SpaceVim $HOME/.SpaceVim
  ln -s .dotfiles/SpaceVim $HOME/.vim
  ln -s .dotfiles/ohmyzsh $HOME/.oh-my-zsh
  if [[ "$(uname -m)" == "x86_64" ]]; then
    ln -s .dotfiles/zprofile-x86_64 $HOME/.zprofile
  else
    ln -s .dotfiles/zprofile $HOME/.zprofile
  fi
  ln -s .dotfiles/zshrc $HOME/.zshrc
  ln -s .dotfiles/zshrc.local $HOME/.zshrc.local

  # some more links
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
  git clone --depth=1 https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab

  ln -s .dotfiles/bin $HOME/bin
  ln -s "/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl" $HOME/bin/subl
  ln -s .dotfiles/gitconfig $HOME/.gitconfig
}

case "$1" in
  macos)
    setup_macos
    ;;
  link)
    setup_symlinks
    ;;
  homebrew)
    setup_homebrew
    ;;
  all)
    setup_homebrew
    setup_macos
    setup_symlinks
  *)
    echo -e $"\nUsage: $(basename "$0") {link|homebrew|shell|terminfo|macos|all}\n"
    exit 1
    ;;
esac

echo -e
success "Done."
