#! /usr/bin/env bash

# TODO: Check if this is macOS

sudo softwareupdate --verbose --install --all --restart --agree-to-license 

# TODO: Figure out if there is a way to resume where we left off
# e.g. Can we register a script to run on boot that opens terminal and runs this script, then do the update command, then unregister the script?
# That way, if the update does not restart, we don't re-run the setup script, but if the update does restart, we continue where we left off?
