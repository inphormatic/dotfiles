#!/bin/sh
source ./utils.sh

clear



# Basic Packages
declare -r INSTALLER=$(find_installer)

if [[ "$?" -ne 0 ]]; then
  log 'error' 'It seems that these dotfiles are not yet available for this Linux distro. Aborting!'
  exit 1
fi

declare -r PKGS='curl dunst feh nodejs picom polybar ripgrep rofi scdoc tmux unzip zsh'

log 'info' "Installing $PKGS ..."
sudo $INSTALLER $PKGS > /dev/null


# Developmet tools
declare -r DISTRO=$(find_distro_name)
declare -Ar DEV_TOOLS=(
  ["arch"]="base-devel"
  ["solus"]="-c system.devel"
  ["ubuntu"]="build-essential"
)

log 'info' 'Installing development tools...'
sudo $INSTALLER ${DEV_TOOLS[$DISTRO]} > /dev/null


# Rust
command -v rustup 1> /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'Rust is already istalled. Skipping!'
else
  log 'info' 'Installing Rust...'
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /dev/null | sh
fi


# Leftwm
command -v leftwm > /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM is already present. Skipping!'
else
  log 'info' 'Installing LeftWM desktop env...'
  log 'info' 'Cloning leftwm repo...'
  git clone https://github.com/leftwm/leftwm.git ./leftwm-repo > /dev/null

  log 'info' 'Building leftwm...'
  cd leftwm-repo
  cargo build --profile optimized > /dev/null
  sudo install -s -Dm755 ./target/optimized/leftwm ./target/optimized/leftwm-worker ./target/optimized/lefthk-worker ./target/optimized/leftwm-state ./target/optimized/leftwm-check ./target/optimized/leftwm-command -t /usr/bin
  sudo cp leftwm.desktop /usr/share/xsessions/

  log 'success' 'LeftWM installed'
  cd .. && rm -rf ./leftwm-repo
fi

# LeftWM config
command -v leftwm-config > /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM-Config already present in ~/.config. Skipping!'
else
  log 'info' 'Installing leftWM configuration...'
  git clone https://github.com/leftwm/leftwm-config.git > /dev/null
  cd ./leftwm-config
  cargo build --release > /dev/null
  sudo cp "$(pwd)"/target/release/leftwm-config /usr/bin/leftwm-config

  log 'success' 'LeftWM-Config installed!'
  cd .. && rm -rf leftwm-config

  log 'info' 'Generating config.ini into ~/.config/leftwm ...'
  leftwm-config -n
fi

# LeftWM theme
command -v leftwm-theme > /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'LeftWM-Theme already installed.'
else
  log 'info' 'Installing leftwm-theme...'
  git clone https://github.com/leftwm/leftwm-theme > /dev/null
  cd leftwm-theme
  cargo build --release > /dev/null

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


# Alacritty
command -v alacritty > /dev/null
if [[ "$?" == 0 ]]; then
  log 'warn' 'Alacritty is already installed. Skipping!'
else
  log 'info' 'Cloning Alacritty repo...'
  git clone https://github.com/alacritty/alacritty.git > /dev/null
  cd alacritty

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

  log 'success' 'Alacritty installed!'
  cd .. && rm -rf alacritty
fi

log 'info' 'Including dotfiles...'
cp -TRa ./leftwm/. "$HOME/.config/leftwm"
cp -TRa ./rofi/. "$HOME/.config/rofi"
cp -TRa ./polybar/. "$HOME/.config/polybar"
cp -TRa ./alacritty/. "$HOME/.config/alacritty"


# Oh-My-Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  log 'warn' 'Oh-My-Zsh is aleady installed. Skipping!'
else
  log 'info' 'Installing Oh-My-Zsh...'
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi



printf "\e[3;97mConfiguration complete!\e[0m\n"
printf "\n\e[1;92mDONE\e[0m\n\n"
printf "\e[1;92mEnjoy your rice\e[0m 🍚\n\n"
