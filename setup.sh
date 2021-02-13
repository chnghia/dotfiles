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
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | bash --login
        curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash --login

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
  ln -s .dotfiles/aliases .aliases
  ln -s .dotfiles/SpaceVim.d .SpaceVim.d
  ln -s .dotfiles/p10k.zsh .p10k.zsh
  ln -s .dotfiles/SpaceVim .SpaceVim
  ln -s .dotfiles/SpaceVim .vim
  ln -s .dotfiles/ohmyzsh .oh-my-zsh
  ln -s .dotfiles/zprofile .zprofile
  ln -s .dotfiles/zshrc .zshrc
  ln -s .dotfiles/zshrc.local .zshrc.local

}

setup_symlinks

echo -e
success "Done."
