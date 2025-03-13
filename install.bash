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

release_dates() {
    echo "$(curl -s http://snapshots.ros.org/$1/ | \
            grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}" | \
            uniq)"
}

error() {
    echo -e "${RED}Error: ${1}${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}Warning: ${1}${NC}" >&2
}

info() {
    if [ -n "${1:-}" ]; then
      echo -e "${GREEN}${1}${NC}"
    else
      echo
    fi
}

usage() {
    info "Usage: $0 -d DISTRO [-s DATESTAMP] [-t] [-h]"
    info
    info "Options:"
    info "  -d DISTRO       ROS 2 distribution to install (required)"
    info "  -s DATESTAMP    Use specific sync datestamp"
    info "  -t              Use testing repositories"
    info "  -h              Display this help message"
    info
    info "Available distributions:"
    info "$(get_active_ros2_distributions)"
    exit 1
}

# Default values
distro=""
sync_datestamp=""
use_testing=false

# Parse arguments using getopts
while getopts "d:s:th" opt; do
  case $opt in
    d) distro="$OPTARG" ;;
    s) sync_datestamp="$OPTARG" ;;
    t) use_testing=true ;;
    h) usage ;;
    \?) error "Invalid option: -$OPTARG" ;;
    :) error "Option -$OPTARG requires an argument." ;;
  esac
done

# Shift positional parameters
shift $((OPTIND-1))

# Validate required arguments
if [ -z "$distro" ]; then
    error "Distribution name is required.\nRun '$0 -h' for usage information."
fi

if [ -n "$sync_datestamp" ] && [ "$use_testing" = true ]; then
    error "Cannot use snapshot (-s) and testing (-t) options together."
fi

# Validate distribution
distros=$(get_active_ros2_distributions)
if ! echo "$distros" | grep -qx "$distro"; then
    error "Invalid distribution name: '$distro'\nAvailable distributions:\n$distros"
fi

if [ -n "$sync_datestamp" ]; then
    sync_datestamps=$(release_dates $distro)
    if ! echo "$sync_datestamps" | grep -qx "$sync_datestamp"; then
        error "Invalid sync_datestamp: '$sync_datestamp'\nAvailable sync_datestamps for $distro:\n$sync_datestamps"
    fi
fi

if [ ! -f /etc/os-release ] || ! grep -q "Ubuntu" /etc/os-release; then
    error "Error: This script only works on Ubuntu"
fi

# Installation based on https://docs.ros.org/en/rolling/Installation/Ubuntu-Install-Debs.html
info "Installing ROS 2 $distro"

if [ -n "$sync_datestamp" ]; then
    info "Using ROS 2 snapshot repository with sync_datestamp: $sync_datestamp"
fi

if [ "$use_testing" = true ]; then
    info "Using ROS 2 testing repositories"
fi

export DEBIAN_FRONTEND=noninteractive

locale  # check for UTF-8

sudo apt update && sudo DEBIAN_FRONTEND=noninteractive apt install -y locales
sudo locale-gen en_US en_US.UTF-8
sudo update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
export LANG=en_US.UTF-8

locale  # verify settings

sudo apt install -y software-properties-common
sudo add-apt-repository -y universe

# Add repository with sync_datestamp if provided. See https://wiki.ros.org/SnapshotRepository and  http://snapshots.ros.org/
if [ -n "$sync_datestamp" ]; then
  sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key 4B63CF8FDE49746E98FA01DDAD19BAB3CBF125EA
  echo "deb [arch=$(dpkg --print-architecture)] http://snapshots.ros.org/${distro}/${sync_datestamp}/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros-snapshots.list > /dev/null
else
  sudo curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key -o /usr/share/keyrings/ros-archive-keyring.gpg
  repo_type="ros2"
  if [ "$use_testing" = true ]; then
      repo_type="ros2-testing"
  fi
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/$repo_type/ubuntu $(. /etc/os-release && echo $UBUNTU_CODENAME) main" | sudo tee /etc/apt/sources.list.d/ros2.list > /dev/null
fi

sudo apt update
sudo apt upgrade -y
# tzdata will prompt for user input, so we need to avoid that
sudo DEBIAN_FRONTEND=noninteractive apt install -y ros-${distro}-desktop
sudo apt install -y ros-dev-tools

info "ROS 2 $distro installed successfully"
