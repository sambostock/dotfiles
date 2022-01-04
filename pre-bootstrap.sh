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
     # macOS comes with a `git` executable, but all it does is prompt to install Command Line Tools and exit unsuccessfully.
     # We can re-run it every second to check if it has installed sucessfully or not.
     # AFAIK, there is no way to bypass the prompt and install automatically.
     echo 'Ensuring git is installed...'
     until git --version > /dev/null 2>&1; do sleep 1; done

     which git

     echo "This is where we would continue with cloning the dotfiles repo and bootstrapping from there..."
     ;;

     *)
     echo "Unsupported or unknown OS: $(uname -s)"
     ;;

esac
