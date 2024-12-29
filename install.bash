#!/usr/bin/env bash

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Function to get active ROS 2 distributions
get_active_ros2_distributions() {
    curl -sL https://raw.githubusercontent.com/ros/rosdistro/master/index.yaml | \
    grep "distribution_cache: http://repo.ros2.org/rosdistro_cache/" | \
    cut -d'/' -f5 | \
    cut -d'-' -f1
}

error() {
    echo -e "${RED}Error: ${1}${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}Warning: ${1}${NC}" >&2
}

info() {
    echo -e "${GREEN}${1}${NC}"
}

distros=$(get_active_ros2_distributions)

# Check if distribution argument is provided
if [ "$#" -ne 1 ]; then
    error "Usage: $0 DISTRO_NAME\nAvailable distributions:\n$distros"
fi

if ! echo "$distros" | grep -qx "$1"; then
    error "Invalid distribution name: '$1'\nAvailable distributions:\n$distros"
fi

if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    error "Error: This script only works on Ubuntu"
fi

distro=$1

# Installation based on https://docs.ros.org/en/rolling/Installation/Ubuntu-Install-Debs.html
info "Installing ROS 2 $distro"

locale  # check for UTF-8

sudo apt update && sudo apt install locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale  # verify settings

# TODO: Make sudo optional
sudo apt install software-properties-common
sudo add-apt-repository universe

sudo apt update && sudo apt install curl -y
sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null

sudo apt update
sudo apt upgrade -y
sudo apt install -y ros-${distro}-desktop
sudo apt install -y ros-dev-tools

info "ROS 2 $distro installed successfully"
