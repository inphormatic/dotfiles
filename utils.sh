#!/bin/sh

# Prints a message to the stdout. It takes:
# - logtype ($1): type of message. Accepted values are: 'error', 'info', 'warn'
# - message ($2): text to print.
function log() {
  declare -Ar colors_map=(
    ["error"]="91"
    ["info"]="94"
    ["success"]="92"
    ["warn"]="93"
  )
  local style="\e[1;${colors_map[$1]}m"
  local endstyle="\e[0m"

  printf "$style$1:$endstyle $2\n" 1>&2
}


# Self explanatory. Tries to figure out the name of the distro.
function find_distro_name() {
  declare distro=$(hostnamectl | grep 'Operating' | cut -d: -f 2 | cut -d' ' -f 2 | tr '[:upper:]' '[:lower:]')

  echo "$distro"
  return 0
}


# Search for the current distro's package manager and returns it, if found.
function find_installer() {
  if [[ -f /etc/debian_version ]]; then
    echo "apt install -y"
    return 0
  fi

  declare -Ar distros=(
    ["alpine"]="apk add"
    ["arch"]="pacman --noconfirm -S"
    ["fedora"]="dnf install -y"
    ["solus"]="eopkg install -y"
  )

  for distro in "${!distros[@]}"
  do
    if [[ -f "/etc/${distro}-release" ]]; then
      echo "${distros[$distro]}"
      return 0
    fi
  done

  return 1
}
