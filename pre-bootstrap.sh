#!/usr/bin/env bash

# This script's purpose is to acquire the dotfiles repo and run its bootstrap script.
# We may update the system along the way to ensure we start off fresh.
# No point installing a bunch of old stuff only to have to update it immediately.

########################################
#                Config                #
########################################

# Make Bash strict
#   -e  Exit immediately if a command exits with a non-zero status.
#   -u  Treat unset variables as an error when substituting.
set -eu

set -x # TODO: Stop echoing commands after this is stable

# Use Shopify/dev convention
DOTFILES_DIR="$HOME/src/github.com/sambostock/dotfiles"

DOTFILES_URL="https://github.com/sambostock/dotfiles.git"

# TODO: Remove this once stable, or make into CLI argument
DOTFILES_BRANCH="m1"

########################################
#            Infrastructure            #
########################################

blindly_update_macos() {
	# Skip if no updates
	[ softwareupdate --list | grep -q "No new software available." ] && return 0

	echo "Blindly installing all software updates. If a reboot occurs, simply re-run this script."
	sudo softwareupdate --verbose --install --all --restart --agree-to-license
	echo "Looks like no reboot occured!"
}

# Adapted from Homebrew's installation script
#   https://github.com/Homebrew/install/blob/master/install.sh
#
#   BSD 2-Clause License
#   
#   Copyright (c) 2009-present, Homebrew contributors
#   All rights reserved.
#   
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions are met:
#   
#   * Redistributions of source code must retain the above copyright notice, this
#     list of conditions and the following disclaimer.
#   
#   * Redistributions in binary form must reproduce the above copyright notice,
#     this list of conditions and the following disclaimer in the documentation
#     and/or other materials provided with the distribution.
#   
#   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
#   AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
#   DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
#   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
#   DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
#   SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
#   CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
#   OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
#   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
ensure_macos_git_installed() (
	# We can't just check `which git` because macOS ships with a `git`
	# executable that just prompts the user to install Command Line Tools.
	xcode_clt_git_installed() {
	  [[ -e "/Library/Developer/CommandLineTools/usr/bin/git" ]]
	}

        # Skip if we already have Git installed
        xcode_clt_git_installed && return 0
  
	# Too much of a pain to inline/reimplement this utility from Homebrew, so we copy it too.
        chomp() { printf "%s" "${1/"$'\n'"/}" }

        # Ensure we have sudo to perform installation
        sudo -v

	# The rest of this is all Homebrew, minus some resilience and flexibility utilities.
	#
	#     hic sunt dracones

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
        
        printf "%s" "${1/"$'\n'"/}"
        
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

clone_dotfiles() (
	mkdir -p $DOTFILES_DIR
	cd $DOTFILES_DIR

        # Are dotfiles already checked out?
	if [ -d .git ]
	then
                # Is git repo clean? (i.e. no changes, untracked files)
		if [ -z "$(git status --porcelain)" ]
		then
			git pull --ff-only
		else
			echo "Not updating dirty dotfiles git repo"
		fi
	else
		git clone $DOTFILES_URL $DOTFILES_DIR
	fi

	git checkout $DOTFILES_BRANCH
)

bootstrap() (
  cd $DOTFILES_DIR && ./bootstrap.sh
)

########################################
#             Actual Work              #
########################################

case "$(uname -s)" in
     Darwin)
	     blindly_update_macos
	     ensure_macos_git_installed
     ;;

     *)
	     echo "Unsupported or unknown OS: $(uname -s)"
	     exit 1
     ;;
esac

clone_dotfiles
bootstrap
