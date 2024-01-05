#!/bin/bash
source ./utils.sh

clear



declare -r INSTALLER=$(find_installer)
declare -r DISTRO=$(find_distro_name)


# Basic Packages
declare -r PKGS='curl dunst fd feh i3 nodejs picom polybar redshift ripgrep rofi scdoc tmux unzip zsh'

log 'info' "Installing $PKGS ..."
sudo $INSTALLER $PKGS


# Developmet tools
declare -Ar DEV_TOOLS=(
  ["arch"]="--needed base-devel"
  ["solus"]="-c system.devel"
  ["ubuntu"]="build-essential"
)

log 'info' 'Installing development tools...'
sudo $INSTALLER ${DEV_TOOLS[$DISTRO]}

if [[ "$DISTRO" = "arch" ]]; then
  log 'info' 'Installing additional packages for Arch Linux...'
  sudo $INSTALLER man-db man-pages npm fuse2 fuse3 xorg-xrandr arandr

  log 'info' 'Cloning Paru AUR helper...'
  git clone https://aur.archlinux.org/paru.git
  log 'info' 'Installing Paru...'
  cd paru
  makepkg -si
  cd .. && rm -rf paru
fi


# Rust
command -v rustup > /dev/null
if [[ "$?" == 0 ]]; then
  log 'info' 'Rust is already istalled. Skipping!'
else
  log 'info' 'Installing Rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  source "$HOME/.cargo/env"
fi


# Go
command -v go > /dev/null
if [[ "$?" == 0 ]]; then
  log 'info' 'Go is already installed. Skipping!'
else
  log 'info' 'Downloading Go...'
  curl -sLO https://go.dev/dl/go1.21.5.linux-amd64.tar.gz

  log 'info' 'Installing Go...'
  tar xfz go1.21.5.linux-amd64.tar.gz
  sudo mv go /usr/local
  rm -rf go1.21.5.linux-amd64.tar.gz
fi


# Nerd Fonts
if [[ -d '/usr/share/fonts/JetBrainsMono' ]]; then
  log 'info' 'JetBrainsMono already present into /usr/share/fonts. Skipping!'
else
  log 'info' 'Downloading JetBrainsMono Nerd Fonts...'
  curl -sLO https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip

  log 'info' 'Unzipping JetBrainsMono...'
  unzip -q JetBrainsMono.zip -d JetBrainsMono
  rm -rf JetBrainsMono.zip

  log 'info' 'Installing JetBrainsMono...'
  sudo mv JetBrainsMono /usr/share/fonts
fi


# Neovim
command -v nvim > /dev/null
if [[ "$?" == 0 ]]; then
  log 'info' 'Neovim is already installed. Skipping!'
else
  log 'info' 'Installing Neovim...'
  curl -sLO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
  mv nvim.appimage nvim
  chmod u+x nvim
  sudo mv nvim /usr/bin
fi

if [[ -d "$HOME/.config/nvim" ]]; then
  log 'info' 'A Neovim configuration is already present at ~/.config/nvim. Skipping!'
else
  log 'info' 'Cloning Neovim configuration...'
  git clone https://github.com/inphormatic/dotvim.git ~/.config/nvim
fi


# Alacritty
command -v alacritty > /dev/null
if [[ "$?" == 0 ]]; then
  log 'info' 'Alacritty is already installed. Skipping!'
else
  log 'info' 'Cloning Alacritty repo...'
  git clone https://github.com/alacritty/alacritty.git ./alacritty-repo > /dev/null
  cd alacritty-repo

  declare -Ar DEPS_BY_DISTRO=(
    ["arch"]="cmake freetype2 fontconfig pkg-config make libxcb libxkbcommon python"
    ["solus"]="fontconfig-devel"
    ["ubuntu"]="cmake pkg-config libfreetype6-dev libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3"
  )

  log 'info' 'Installing dependencies'
  sudo $INSTALLER ${DEPS_BY_DISTRO[$DISTRO]}

  log 'info' 'Building Alacritty...'
  cargo build --release > /dev/null

  log 'info' 'Adding Alacritty desktop entry...'
  sudo cp target/release/alacritty /usr/bin/alacritty
  sudo cp extra/logo/alacritty-term.svg /usr/share/pixmaps/Alacritty.svg
  sudo desktop-file-install extra/linux/Alacritty.desktop
  sudo update-desktop-database

  log 'info' 'Installing Alacritty manpages...'
  sudo mkdir -p /usr/local/share/man/man1
  sudo mkdir -p /usr/local/share/man/man5
  scdoc < extra/man/alacritty.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty.1.gz > /dev/null
  scdoc < extra/man/alacritty-msg.1.scd | gzip -c | sudo tee /usr/local/share/man/man1/alacritty-msg.1.gz > /dev/null
  scdoc < extra/man/alacritty.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty.5.gz > /dev/null
  scdoc < extra/man/alacritty-bindings.5.scd | gzip -c | sudo tee /usr/local/share/man/man5/alacritty-bindings.5.gz > /dev/null

  cd .. && rm -rf alacritty-repo
fi


# EWW Widgets
if [[ -d "$HOME/.config/eww" ]]; then
  log 'info' 'EWW Widgets are already installed'
else
  log 'info' 'Cloning EWW Widgets...'
  git clone https://github.com/elkowar/eww
  cd eww

  log 'info' 'Building EWW Widgets...'
  cargo build --release --no-default-features --features x11
  cd .. && rm -rf eww
fi


# Oh-My-Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log 'info' 'Oh-My-Zsh is aleady installed. Skipping!'
else
  log 'info' 'Installing Oh-My-Zsh...'
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  log 'info' 'Installing zsh-autosuggestions'
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
fi


# Dotfiles inclusion
log 'info' 'Including dotfiles...'
cp -TRa ./i3/. "$HOME/.config/i3"
cp -TRa ./picom/. "$HOME/.config/picom"
cp -TRa ./dunst/. "$HOME/.config/dunst"
cp -TRa ./rofi/. "$HOME/.config/rofi"
cp -TRa ./polybar/. "$HOME/.config/polybar"
cp -TRa ./alacritty/. "$HOME/.config/alacritty"
cp -a ./tmux/. "$HOME"
cp -a ./zsh/. "$HOME"



printf "\e[3;97mConfiguration complete!\e[0m\n"
printf "\n\e[1;92mDONE\e[0m\n\n"
printf "\e[1;92mEnjoy your rice\e[0m 🍚\n\n"
