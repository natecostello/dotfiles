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

# Install priv-allocate (private repository - requires SSH key)
echo "Checking priv-allocate..."
if command -v priv-allocate &> /dev/null; then
    echo "  priv-allocate is already installed"
else
    echo "  Installing priv-allocate from GitHub (private repo)..."
    # Check if SSH key exists and is added to ssh-agent
    if [ ! -f ~/.ssh/id_ed25519 ]; then
        echo "  ✗ SSH key not found at ~/.ssh/id_ed25519"
        echo "  Please set up SSH keys first (see Section 7.3)"
        exit 1
    fi
    
    if pipx install git+ssh://git@github.com/natecostello/util-priv-allocate.git; then
        echo "  ✓ priv-allocate installed successfully"
    else
        echo "  ✗ Failed to install priv-allocate"
        echo "  Make sure your SSH key is added to GitHub and has access to the repository"
        exit 1
    fi
fi

echo ""
echo "Python utilities installation complete!"
echo ""
echo "Installed commands:"
echo "  - toggl-to-zoho: Convert Toggl time tracking CSV to Zoho Books format"
echo "  - priv-allocate: Private allocation utility"
echo ""
