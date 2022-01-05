#!/usr/bin/env bash

# This script's goal is to do the following as quickly and reliably as possible on a new machine:
# - clone dotfiles
# - run bootstrap.sh

# Make Bash strict
#   -e  Exit immediately if a command exits with a non-zero status.
#   -u  Treat unset variables as an error when substituting.
set -eu

set -x # TODO: Stop echoing commands after this is stable

# Also stolen from Homebrew
chomp() {
  printf "%s" "${1/"$'\n'"/}"
}

# Thanks homebrew
xcode_clt_git_installed() {
     # We can't just check `which git` because macOS ships with a `git`
     # executable that just prompts the user to install Command Line Tools.
     [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
}

# Adapted from from https://github.com/Homebrew/install/blob/master/install.sh
install_xcode_clt() {
  echo "Searching online for the Command Line Tools"
  # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
  clt_placeholder="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
  sudo touch "${clt_placeholder}"
  
  clt_label_command="/usr/sbin/softwareupdate -l |
                      grep -B 1 -E 'Command Line Tools' |
                      awk -F'*' '/^ *\\*/ {print \$2}' |
                      sed -e 's/^ *Label: //' -e 's/^ *//' |
                      sort -V |
                      tail -n1"
  clt_label="$(chomp "$(/bin/bash -c "${clt_label_command}")")"
  
  if [[ -n "${clt_label}" ]]
  then
    echo "Installing ${clt_label}"
    sudo "/usr/sbin/softwareupdate" "-i" "${clt_label}"
    sudo "/bin/rm" "-f" "${clt_placeholder}"
    sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
  fi
  
  # Headless install may have failed, so fallback to original 'xcode-select' method
  if ! xcode_clt_git_installed
  then
    echo "Installing the Command Line Tools (expect a GUI popup):"
    sudo "/usr/bin/xcode-select" "--install"
    echo "Press enter when the installation has completed."
    read
    sudo "/usr/bin/xcode-select" "--switch" "/Library/Developer/CommandLineTools"
  fi
  
  if ! output="$(/usr/bin/xcrun clang 2>&1)" && [[ "${output}" == *"license"* ]]
  then
    echo "$(
      cat <<EOABORT
You have not agreed to the Xcode license.
Before running the installer again please agree to the license by opening
Xcode.app or running:
    sudo xcodebuild -license
EOABORT
    )"
    exit 1
  fi
}

ensure_git_installed_macos() {
     # Check if we already have Git installed
     xcode_clt_git_installed && return 0

     sudo -v # Ensure we have sudo to perform installation

     install_xcode_clt # Install XCode Command Line Tools, which includes git
}

clone_dotfiles() {
	# Use Shopify/dev convention
	local destination_dir="$HOME/src/github.com/sambostock"
	mkdir -p $destination_dir
	git clone https://github.com/sambostock/dotfiles.git $destination_dir
}


case "$(uname -s)" in

     Darwin)
	     ensure_git_installed_macos

	     clone_dotfiles

	     echo "This is where we could continue with bootstraping dotfiles..."
     ;;

     *)
     echo "Unsupported or unknown OS: $(uname -s)"
     ;;

esac
