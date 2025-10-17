#!/bin/bash
# Install private Python utility scripts via pipx
# Requires: SSH keys configured (Section 7.3)
set -euo pipefail

echo "Installing private Python utility scripts..."

# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "ERROR: pipx is not installed. Please install it first:"
    echo "  brew install pipx"
    exit 1
fi

# Check if SSH key exists
if [ ! -f ~/.ssh/id_ed25519 ]; then
    echo "ERROR: SSH key not found at ~/.ssh/id_ed25519"
    echo "Please set up SSH keys first (see Section 7.3 in BOOTSTRAP.md)"
    echo ""
    echo "Quick setup:"
    echo "  ssh-keygen -t ed25519 -C 'your-email@example.com' -f ~/.ssh/id_ed25519"
    echo "  ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
    echo "  pbcopy < ~/.ssh/id_ed25519.pub"
    echo "  # Then add to GitHub: Settings → SSH and GPG keys → New SSH key"
    exit 1
fi

# Install allocate (private repository)
echo "Checking allocate..."
if command -v allocate &> /dev/null; then
    echo "  allocate is already installed"
else
    echo "  Installing allocate from GitHub (private repo)..."
    if pipx install git+ssh://git@github.com/natecostello/util-priv-allocate.git; then
        echo "  ✓ allocate installed successfully"
    else
        echo "  ✗ Failed to install allocate"
        echo "  Make sure your SSH key is added to GitHub with access to the repository"
        echo "  Test SSH access: ssh -T git@github.com"
        exit 1
    fi
fi

echo ""
echo "Private Python utilities installation complete!"
echo ""
echo "Installed commands:"
echo "  - allocate: Private allocation utility"
echo ""
