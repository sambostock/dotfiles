#!/usr/bin/env bash

# Make Bash strict
#   -e  Exit immediately if a command exits with a non-zero status.
#   -u  Treat unset variables as an error when substituting.
set -eu

set -x # TODO: Stop echoing commands after this is stable

echo "We made it to the bootstrap!"
