#!/bin/bash
# Install custom Python utility scripts via pipx
set -euo pipefail

echo "Installing Python utility scripts..."

# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "ERROR: pipx is not installed. Please install it first:"
    echo "  brew install pipx"
    exit 1
fi

# Install toggl-to-zoho (public repository)
echo "Checking toggl-to-zoho..."
if command -v toggl-to-zoho &> /dev/null; then
    echo "  toggl-to-zoho is already installed"
else
    echo "  Installing toggl-to-zoho from GitHub..."
    if pipx install git+https://github.com/natecostello/util-toggl-to-zoho.git; then
        echo "  ✓ toggl-to-zoho installed successfully"
    else
        echo "  ✗ Failed to install toggl-to-zoho"
        exit 1
    fi
fi

echo ""
echo "Public Python utilities installation complete!"
echo ""
echo "Installed commands:"
echo "  - toggl-to-zoho: Convert Toggl time tracking CSV to Zoho Books format"
echo ""
echo "Note: Private repository utilities (allocate) are installed separately"
echo "      in run_once_070 after SSH keys are configured (Section 7.3)"
echo ""
