#!/usr/bin/env bash

# This script's goal is to do the following as quickly and reliably as possible on a new machine:
# - clone dotfiles
# - run bootstrap.sh

# Set the following bash options
#   -e  Exit immediately if a command exits with a non-zero status.
#   -u  Treat unset variables as an error when substituting.
#   -x  Print commands and their arguments as they are executed.
set -eux

case "$(uname -s)" in

     Darwin)
     # macOS has a git executable, but all it does is install command line tools.
     # Therefore, we should go through the steps to install command line tools ourselves first.
     xcode-select --install > /dev/null 2>&1
     if [ 0 == $? ]; then
       sleep 1
       osascript <<'APPLESCRIPT'
         tell application "System Events"
           tell process "Install Command Line Developer Tools"
             keystroke return
             click button "Agree" of window "License Agreement"
             end tell
           end tell
APPLESCRIPT
     else
	echo "Command Line Developer Tools are already installed!"
     fi

     which git
     ;;

     *)
     echo "Unsupported or unknown OS: $(uname -s)"
     ;;

esac
