#!/usr/bin/env bash

# High-level overview:
# This is a chezmoi run-once script that automatically installs iTerm2 shell
# integration on macOS.
#
# What it does:
# 1. Checks if running on macOS - Exits if not on Darwin (macOS), since iTerm2
#    is Mac-only
# 2. Checks if already installed - Skips installation if
#    ~/.iterm2_shell_integration.zsh already exists
# 3. Downloads and installs - Curls the official iTerm2 shell integration
#    installer script and runs it
# 4. Verifies installation - Checks that the integration file was created
#    successfully
#
# The run_once_ prefix means chezmoi will only execute this script once
# (tracking it via a state file), and the 020- prefix controls the execution
# order relative to other run-once scripts. The .tmpl extension indicates it's
# a chezmoi template (though this particular file doesn't use any templating
# features).
#
# This ensures iTerm2's enhanced shell features (like semantic history, shell
# integration marks, etc.) are automatically set up when you initialize your
# dotfiles on a new Mac.


set -euo pipefail

# Only on macOS; iTerm2-only feature
if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 0
fi

# If the integration file already exists, skip
if [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  echo "iTerm2 shell integration already present; skipping."
  exit 0
fi

# If iTerm2 isn't installed yet, it's still fine—this just drops the files in place.
# Install official shell integration + utilities
curl -Ls https://iterm2.com/shell_integration/install_shell_integration_and_utilities.sh | bash

# Safety check
if [[ -f "${HOME}/.iterm2_shell_integration.zsh" ]]; then
  echo "iTerm2 shell integration installed."
else
  echo "Failed to install iTerm2 shell integration." >&2
  exit 1
fi

