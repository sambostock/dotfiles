#!/usr/bin/env bash

# Make Bash strict
#   -e  Exit immediately if a command exits with a non-zero status.
#   -u  Treat unset variables as an error when substituting.
set -eu

set -x # TODO: Stop echoing commands after this is stable

shopify_only() {
	install_dev
}

personal_only() {
	install_minidev
}

install_dev() {
	eval "$(curl -sS https://up.dev)"
}

install_minidev() (
	local minidev_dir=~/src/github.com/burke/minidev
	mkdir -p $minidev_dir && cd $minidev_dir
	git clone https://github.com/burke/minidev .

	# TODO: Do this and remove the message!
        echo "$(
          cat <<EOMESSAGE
Remember to finish setting up Minidev sourcing!

    if [ -f /opt/dev/dev.sh ]; then
      source /opt/dev/dev.sh
    elif [ -f ~/src/github.com/burke/minidev/dev.sh ]; then
      source ~/src/github.com/burke/minidev/dev.sh
    fi

EOMESSAGE
        )"
)

install_homebrew() {
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

sync_and_trigger_brewfile() {
	# https://github.com/Homebrew/homebrew-bundle
	cp Brewfile "$HOME/"
	brew bundle install --file "$HOME/Brewfile"
}

write_defaults() {
	# Defer statements like "killall Finder" until we're done writing defaults.
	# We'll repeat ourselves, but it will keep the code atomic.
	local killalls=()
	##############################

	# Show hidden files
	# https://www.groovypost.com/howto/cool-macos-terminal-commands
	defaults write com.apple.finder AppleShowAllFiles -bool TRUE && \
		killalls+=("Finder")

	# Save screenshots here instead of ~/Desktop
	# https://www.groovypost.com/howto/cool-macos-terminal-commands
	defaults write com.apple.screencapture location ~/Pictures/Screenshots && \
		killalls+=("SystemUIServer")

	# Show all file extensions
	# https://medium.com/swlh/top-mac-os-default-behaviors-you-should-consider-changing-419b679fe290
	defaults write -g AppleShowAllExtensions -bool true && \
		killalls+=("Finder")

	# Auto-hide dock
	# https://git.herrbischoff.com/awesome-macos-command-line/about/#automatically-hide
	defaults write com.apple.dock autohide -bool true && \
		killalls+=("Dock")

	# Resize dock
	# https://git.herrbischoff.com/awesome-macos-command-line/about/#resize
	# DOES NOT WORK?
	# defaults write com.apple.dock tilesize -int 0 && \
		# killalls+=("Dock")

	# https://git.herrbischoff.com/awesome-macos-command-line/about/#set-login-window-text
	# sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "Your text"

	# Set the menu bar clock format
	# https://git.herrbischoff.com/awesome-macos-command-line/about/#set-menu-bar-clock-output-format
	defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d  h:mm:ss a"

	##############################
	# Kill the entire list, with fancy quoting
	killall $(printf "'%s' " "${array[@]}")
}

# Heuristic for "is this a work computer?"
# TODO: Should we promote this to a file that runs prior to the rest of the bootstrap?
if [ profiles -H | grep -q "profiles are installed on this system" ]
then
	SHOPIFY=true
	shopify_only
else
	personal_only
fi

install_homebrew
sync_and_trigger_brewfile
write_defaults

# TODO: Setup ssh keys?
# TODO: Setup wifi network?
#       https://git.herrbischoff.com/awesome-macos-command-line/about/#join-a-wi-fi-network
#       networksetup -setairportnetwork en0 WIFI_SSID WIFI_PASSWORD
