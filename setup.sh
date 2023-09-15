#!/bin/sh
source ./utils.sh

clear


# Basic Packages
declare -r INSTALLER=$(find_installer)

if [[ "$?" -ne 0 ]]; then
  log 'error' 'It seems that these dotfiles are not yet available for this Linux distro. Aborting!'
  exit 1
fi

declare -r PKGS='curl dunst feh nodejs picom polybar ripgrep rofi tmux unzip zsh'

log 'info' "Installing $PKGS ..."
sudo $INSTALLER $PKGS 1> /dev/null


# Developmet tools
declare -r DISTRO=$(find_distro_name)
declare -Ar DEV_TOOLS=(
  ["arch"]='base-devel'
  ["ubuntu"]='build-essential'
  ["solus"]='-c system.devel'
)

log 'info' 'Installing development tools...'
sudo $INSTALLER ${DEV_TOOLS[$DISTRO]} 1> /dev/null


# Rust
command -v rustup 1> /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'Rust is already istalled. Skipping!'
else
  log 'info' 'Installing Rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs 1> /dev/null | sh
fi


# Leftwm
command -v leftwm 1> /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM is already present. Skipping!'
else
  log 'info' 'Installing LeftWM desktop env...'
  log 'info' 'Cloning leftwm repo...'
  git clone https://github.com/leftwm/leftwm.git ./leftwm-repo 1> /dev/null

  log 'info' 'Building leftwm...'
  cd leftwm-repo
  cargo build --profile optimized 1> /dev/null
  sudo install -s -Dm755 ./target/optimized/leftwm ./target/optimized/leftwm-worker ./target/optimized/lefthk-worker ./target/optimized/leftwm-state ./target/optimized/leftwm-check ./target/optimized/leftwm-command -t /usr/bin
  sudo cp leftwm.desktop /usr/share/xsessions/

  log 'success' 'LeftWM installed'
  cd .. && rm -rf ./leftwm-repo
fi

# LeftWM config
command -v leftwm-config 1> /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM-Config already present in ~/.config. Skipping!'
else
  log 'info' 'Installing leftWM configuration...'
  git clone https://github.com/leftwm/leftwm-config.git 1> /dev/null
  cd ./leftwm-config
  cargo build --release 1> /dev/null
  sudo cp "$(pwd)"/target/release/leftwm-config /usr/bin/leftwm-config

  log 'success' 'LeftWM-Config installed!'
  cd .. && rm -rf leftwm-config

  log 'info' 'Generating config.ini into ~/.config/leftwm ...'
  leftwm-config -n
fi

# LeftWM theme
command -v leftwm-theme 1> /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM-Theme already installed.'
else
  log 'info' 'Installing leftwm-theme...'
  git clone https://github.com/leftwm/leftwm-theme 1> /dev/null
  cd leftwm-theme
  cargo build --release 1> /dev/null

  log 'success' 'Leftwm-theme installed!'
  sudo install -s -Dm755 ./target/release/leftwm-theme -t /usr/bin
  cd .. && rm -rf leftwm-theme
fi

if [[ -f "$HOME/.config/leftwm/themes.toml" ]]; then
  log 'info' 'Themes already upgraded'
else
  log 'info' 'Generating themes.toml into ~/.config/leftwm...'
  leftwm-theme update
fi

if [[ -d "$HOME/.config/leftwm/themes" ]]; then
  log 'warn' 'A LeftWM theme already exists. Remove it if you want to apply a new one.'
else
  log 'info' 'Installing LeftWM Ascent theme...'
  leftwm-theme install 'Ascent'
  leftwm-theme apply 'Ascent'
  
  if [[ "$?" -ne 0 ]]; then
    log 'error' 'Error during leftwm theme installation. Aborting!'
    exit 1
  fi

  log 'success' 'LeftWM theme installed!'
fi


printf "\e[3;97mConfiguration complete!\e[0m\n"
printf "\n\e[1;92mDONE\e[0m\n\n"
printf "\e[1;92mEnjoy your rice\e[0m 🍚\n\n"
