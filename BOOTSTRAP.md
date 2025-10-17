# Bootstrap Guide: Fresh macOS Machine Setup

This guide walks through setting up a new macOS machine from scratch using this dotfiles repository. Follow these steps in order for a fully configured development workstation.

**Estimated time:** 30-60 minutes (depending on download speeds)

<!-- DONE: Template evaluation complete. Only LaunchAgent plist uses templates ({{ .chezmoi.homeDir }} and {{ if eq .chezmoi.arch }}). All other files renamed to remove unnecessary .tmpl extension. -->

---

## Prerequisites

- **Fresh macOS installation** (or willingness to modify existing setup)
- **Apple ID** (for App Store, iCloud Keychain)
- **Internet connection**
- **LastPass account** with secrets already stored (see [Secret Inventory](#secret-inventory))
- **GitHub access** (if repo is private, need SSH key or token)

---

## Phase 1: Initial macOS Setup

These are the unavoidable manual steps before automation kicks in.

### 1.1 Complete macOS First-Run Setup
- Sign in with Apple ID
- Enable iCloud (optional, but helpful for Keychain sync)
- Set computer name: **System Settings → General → Sharing → Local hostname**
- Enable FileVault: **System Settings → Privacy & Security → FileVault**

### 1.2 Install Xcode Command Line Tools
Required for git, compilers, and Homebrew.

```bash
xcode-select --install
```

Click "Install" in the dialog. Wait for completion (~5-10 minutes).

**Verify:**
```bash
xcode-select -p
# Should output: /Library/Developer/CommandLineTools
```

### 1.3 Grant Terminal Full Disk Access (Optional but Recommended)
Prevents permission issues with LaunchAgents and system files.

1. **System Settings → Privacy & Security → Full Disk Access**
2. Click the **+** button
3. Add **Terminal.app** (and **iTerm2** if you'll install it)

---

## Phase 2: Install Core Bootstrap Tools

### 2.1 Install Homebrew
Package manager for everything else.


```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Follow prompts, enter password when asked. The installer will automatically add Homebrew to your `~/.zprofile`.

**Activate Homebrew in current session:**
```bash
# For Apple Silicon:
eval "$(/opt/homebrew/bin/brew shellenv)"

# For Intel Mac:
eval "$(/usr/local/bin/brew shellenv)"
```

**Verify:**
```bash
brew --version
# Should show: Homebrew 4.x.x
```

### 2.2 Install Bootstrap Tools

Install git, chezmoi, and LastPass CLI:

```bash
brew install git chezmoi lastpass-cli
```

**Verify:**
```bash
git --version
chezmoi --version
lpass --version
```

---

## Phase 3: Authenticate to Secret Manager

### 3.1 Log in to LastPass
This must happen **before** running chezmoi apply, because run-once scripts fetch secrets.

```bash
lpass login your-email@example.com
```

Enter master password and complete 2FA if required.

**Verify:**
```bash
lpass status
# Should show: Logged in as your-email@example.com
```

### 3.2 Test Secret Access
Verify you can read the secrets that will be needed.

```bash
# Test rclone passphrase (should return a passphrase)
lpass show --password rclone/logseq_crypt_passphrase

# Test Dropbox token (should return JSON)
lpass show --notes rclone/dropbox_token
```

If these fail, you need to create the secrets in LastPass first (see [Secret Inventory](#secret-inventory)).

---

## Phase 4: Initialize Dotfiles with chezmoi

### 4.1 Clone and Apply Repository

```bash
chezmoi init --apply https://github.com/natecostello/dotfiles.git
```

**What this does:**
1. Clones the repo to `~/.local/share/chezmoi`
2. Processes all templates (`.tmpl` files)
3. Copies files to their target locations (`dot_*` → `~/.*`)
4. Runs all `run_once_*` scripts in order:
   - `run_once_020-iterm2-shell-integration.sh` → Installs iTerm2 integration
   - `run_once_dropbox_token_to_keychain.sh` → Copies Dropbox token to Keychain
   - `run_once_logseq_crypt_to_keychain.sh` → Copies rclone passphrase to Keychain

**Expected output:**
```
Cloning into '/Users/you/.local/share/chezmoi'...
remote: Enumerating objects...
[...]
Saved Dropbox token to Keychain service: rclone/logseq/dropbox_token
Saved passphrase to Keychain service: rclone/logseq/crypt_passphrase
iTerm2 shell integration installed.
```

### 4.2 Verify Files Were Applied

```bash
# Check shell config
ls -la ~ | grep -E '\.(zshrc|gitconfig|p10k)'

# Check scripts
ls -la ~/.local/bin/

# Check LaunchAgent
ls -la ~/Library/LaunchAgents/com.ncos.backup-logseq.plist

# Check rclone filters
ls -la ~/.config/rclone/filters/
```

All should exist now.

---

## Phase 5: Install Applications and Tools

### 5.1 Install from Brewfile (if implemented)
<!-- DECISION: "We will have a brewfile, building that will be part of this effort." -->
<!-- TODO: "Create Brewfile with essential packages including pipx"
     CLAUDE: The Brewfile should include:
     - CLI tools: gh, rclone, fzf, ripgrep, jq
     - Python tools: pipx (required for Section 7.4 utilities)
     - Shell: powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting
     - Casks: iterm2, visual-studio-code, logseq, dropbox
     - Fonts: font-meslo-lg-nerd-font (via homebrew/cask-fonts tap)
     - Optional: pyenv, neovim, tmux (depending on user preferences)
     
     Example Brewfile format:
     ```
     # Taps
     tap "homebrew/cask-fonts"
     
     # CLI Tools
     brew "gh"
     brew "rclone"
     brew "pipx"  # Required for Python utilities
     
     # Casks
     cask "iterm2"
     cask "visual-studio-code"
     ```
-->
<!-- TODO: "Figure out how to handle brew casks that require sudo (e.g., basictex)"
     CLAUDE: Some brew casks require sudo for installation (LaTeX distributions, system utilities, etc.)
     
     Options:
     1. Interactive Brewfile install - Let brew prompt for sudo during `brew bundle`
        - Pros: Simple, brew handles it
        - Cons: Breaks unattended automation, user must be present
     
     2. Separate Brewfile section - Create separate bundle for sudo-requiring casks
        - Example: Brewfile.sudo with just basictex
        - Document as separate manual step in bootstrap
        - Pros: Clear separation, user knows what needs sudo
        - Cons: Multiple brew bundle commands
     
     3. Run_once script with sudo - Create run_once_050-install-sudo-casks.sh
        - Script runs: sudo brew install --cask basictex
        - Pros: Automated during chezmoi apply
        - Cons: Requires sudo during chezmoi apply (not always desirable)
     
     4. Document as post-bootstrap step - List sudo-requiring casks in Phase 8
        - Keep them out of Brewfile entirely
        - Manual install with instructions
        - Pros: No sudo needed during main bootstrap
        - Cons: Manual step, might be forgotten
     
     5. Quarto TinyTeX alternative (for Quarto users specifically)
        - Skip basictex entirely, use Quarto's built-in LaTeX installer
        - Create run_once_055-install-tinytex.sh with: quarto install tinytex
        - Pros: No sudo required, lighter weight (~100MB vs basictex ~7GB), managed by Quarto
        - Cons: Only works if using Quarto, not a general TeX solution
        - Requires: Quarto already installed via brew (brew install quarto)
     
     Recommendation: Option 5 if primary TeX use is for Quarto. Otherwise Option 2 or 4 
     depending on how many sudo casks you have. If just basictex, document as separate step. 
     If many, create Brewfile.sudo.
-->

If you've added a `Brewfile` to manage apps:

```bash
cd ~/.local/share/chezmoi
brew bundle --file=Brewfile
```

This installs:
- **CLI tools**: gh, rclone, neovim, tmux, fzf, ripgrep, etc.
- **Casks (apps)**: iTerm2, VS Code, Logseq, Dropbox, etc.
- **Language runtimes**: pyenv, node, etc.
- **Python tools**: pipx (for isolated Python app installations)

**If no Brewfile yet**, install manually:
```bash
# Essential GUI apps
brew install --cask iterm2 visual-studio-code logseq dropbox

# Fonts
brew tap homebrew/cask-fonts
brew install --cask font-meslo-lg-nerd-font

# Dev tools
brew install gh rclone neovim tmux fzf ripgrep jq

# Python package installer (required for Section 7.4)
brew install pipx

# Shell enhancements
brew install powerlevel10k zsh-autosuggestions zsh-syntax-highlighting

# Python management
brew install pyenv
```

**Note:** `pipx` is required for the Python utilities in Section 7.4.

### 5.2 Configure pyenv (if applicable)
<!-- TODO: "I'm not sold on pyenv. I thought I might need it, but am open to alternative approaches. Lets mark that as something that needs attention and a decision." -->
<!-- CLAUDE: Options for Python management:
     1. Homebrew Python (`brew install python@3.12`) - Simpler, single version, good for most use cases
     2. pyenv - Multiple versions, project-specific Python versions, more complex
     3. uv/rye - Newer Python project managers, very fast, but newer ecosystem
     
     Recommendation: If you don't need multiple Python versions for different projects, 
     `brew install python` is simpler and sufficient. Only use pyenv if you need to switch 
     between Python 3.10, 3.11, 3.12 for different projects.
     
     For single-user dev machine with one main Python version: Homebrew Python is cleaner.
-->

The dotfiles already set up pyenv in `.zshrc`, but you need to install a Python version:

```bash
pyenv install 3.12.0
pyenv global 3.12.0
```

**Verify:**
```bash
python --version
# Should show: Python 3.12.0
```

---

## Phase 6: Shell and Terminal Setup

### 6.1 Restart Terminal or Source Config

Your new shell config won't take effect until you reload.

**Restart Terminal.app** (Cmd+Q, then reopen)

### 6.2 Verify Shell Enhancements

**Check Powerlevel10k prompt:**
- Should see a fancy prompt with git status, time, etc.
- Configuration wizard should NOT run (config already applied via chezmoi)

**Check zsh-autosuggestions:**
- Start typing a command you've used before
- Should see gray text suggesting completion

**Check syntax highlighting:**
- Type a valid command → should turn green
- Type invalid command → should turn red

### 6.3 Verify iTerm2 Configuration

iTerm2 preferences are managed via chezmoi and stored in `~/.config/iterm2/`. Your colors, fonts, profiles, and keybindings were applied automatically during Phase 4.

**Verify settings loaded correctly:**
- Open **iTerm2**
- Check that your preferred color scheme is active
- Verify MesloLGS NF font displays correctly (you should see all p10k icons)
- Test any custom keybindings or profiles

**To customize iTerm2 settings:**
1. Make changes in iTerm2 Preferences
2. Settings are automatically saved to `~/.config/iterm2/com.googlecode.iterm2.plist`
3. Add changes to dotfiles: `chezmoi add ~/.config/iterm2/com.googlecode.iterm2.plist`
4. Commit: `cd ~/.local/share/chezmoi && git add . && git commit -m "Update iTerm2 config"`

---

## Phase 7: Module-Specific Setup

### 7.1 Logseq Backup Module
<!-- TODO: "Is there away to set logseq graph at ~/Logseq via chezmoi script (simply - i know anything is possible)." -->
<!-- CLAUDE: Logseq stores settings in JSON/EDN files in:
     - ~/Logseq/.logseq/settings/ (graph-specific settings)
     - ~/.logseq/ (application settings)
     
     You could script editing these files to set the graph location, but it's complex:
     - Need to parse JSON/EDN
     - Settings format varies by Logseq version
     - Graph location might not even be a setting (just opens last used)
     
     Simpler approach: Just document that the graph should be at ~/Logseq
     
     Even better: Have a run_once script that restores from backup if ~/Logseq doesn't exist
     This ensures the graph is there and properly located.
-->
<!-- TODO: "Is there away to load launchAgent via chezmoi script?" -->
<!-- CLAUDE: Absolutely yes! Perfect use case for a run_once script.
     
     Create: run_once_030-load-backup-launchagent.sh.tmpl
     
     Contents:
     #!/bin/bash
     set -euo pipefail
     
     # Only load if not already loaded
     if launchctl list | grep -q com.ncos.backup-logseq; then
       echo "LaunchAgent already loaded, skipping."
       exit 0
     fi
     
     launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ncos.backup-logseq.plist
     echo "Loaded backup-logseq LaunchAgent."
     
     This runs once during chezmoi apply and loads the agent automatically.
-->
<!-- TODO: "Should we pull the latest snapshot from dropbox to ~/Logseq via chezmoi script?" -->
<!-- CLAUDE: Great idea! Add a run_once script to restore if graph doesn't exist.
     
     Create: run_once_025-restore-logseq-if-missing.sh.tmpl
     
     Logic:
     1. Check if ~/Logseq exists and has content
     2. If not, list available snapshots (daily/weekly/monthly)
     3. Either:
        a) Automatically restore latest daily snapshot, OR
        b) Prompt user to choose which snapshot to restore
     
     This ensures a fresh machine gets the Logseq graph automatically.
     
     Considerations:
     - Requires rclone to be installed (dependency ordering)
     - Requires secrets already in Keychain (runs after those scripts)
     - Might want to make it optional/prompt-based rather than automatic
     - Could be slow if graph is large (document expected time)
     
     Implementation: Add after secrets are loaded but before LaunchAgent starts.
-->

**Prerequisites:**
- Dropbox account with API access token in LastPass
- rclone passphrase in LastPass
- Logseq installed and graph at `~/Logseq`

**Verify secrets in Keychain:**
```bash
security find-generic-password -a "$USER" -s rclone/logseq/dropbox_token -w
security find-generic-password -a "$USER" -s rclone/logseq/crypt_passphrase -w
```

Both should return values (token JSON and passphrase).

**Load the LaunchAgent:**
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ncos.backup-logseq.plist
```

**Verify it's loaded:**
```bash
launchctl list | grep backup-logseq
# Should show: -  0  com.ncos.backup-logseq
```

**Test backup manually (optional):**
```bash
~/.local/bin/backup-logseq
```

Check logs:
```bash
tail ~/Library/Logs/backup-logseq.log
```

**List remote snapshots:**
```bash
~/.local/bin/list-logseq
```

The LaunchAgent will now run automatically daily at 10:00 AM.

### 7.2 Logseq Configuration and Plugins
<!-- TODO: "Need to add Logseq global config files to chezmoi" -->
<!-- CLAUDE: Add these files to version control:
     - ~/.logseq/preferences.json (app-wide preferences)
     - ~/.logseq/config/config.edn (global config)
     - ~/.logseq/config/plugins.edn (plugin settings)
     
     Command: chezmoi add ~/.logseq/preferences.json ~/.logseq/config/config.edn ~/.logseq/config/plugins.edn
-->
<!-- TODO: "Decide on plugin management strategy" -->
<!-- DECISION: Choose between:
     Option A: Full plugin tracking (recommended for <50MB total)
       - Add entire plugin directories to chezmoi: chezmoi add --recursive ~/.logseq/plugins/
       - Pros: Complete automation, exact versions, offline restore
       - Cons: Larger repo size, need to remember to re-add when plugins change
     
     Option B: Config-only tracking
       - Only track config files that list plugins
       - Manually reinstall plugins from marketplace on fresh machine
       - Pros: Minimal tracking, documentation-focused
       - Cons: Manual reinstall needed, might get newer versions
     
     Current plugin size: ~20MB (10 plugins), manageable for Option A
-->
<!-- CLAUDE: Recommended approach - Track complete plugin directories in chezmoi
     
     Benefits:
     - Complete automation (no manual reinstall)
     - Exact plugin versions preserved
     - Settings included with plugin code
     - Offline restore capability
     - 20MB is manageable for version control
     
     Current plugins (~20MB total):
     - logseq-agenda (3.3MB)
     - logseq-journals-calendar (3.4MB)
     - logseq-reference-styles (3.6MB)
     - logseq-osmmaps-plugin (4.4MB)
     - logseq-plugin-show-weekday-and-week-number (2.0MB)
     - logseq-plugin-weather (1.4MB)
     - logseq-smartblocks (628KB)
     - logseq-dev-theme (572KB)
     - logseq-pdf-export-plugin (360KB)
     - logseq-helium-plugin (148KB)
-->
<!-- CLAUDE: Options for tracking plugin changes:
     
     1. Manual periodic check (simplest):
        - Monthly reminder to run `chezmoi diff ~/.logseq/plugins/`
        - Explicitly review and commit changes
     
     2. Git pre-commit hook (automated reminder):
        - Hook warns if plugins changed but not committed
        - Forces attention before pushing other dotfile changes
     
     3. Wrapper script (semi-automated):
        - Create ~/bin/sync-logseq.sh
        - Checks for changes, shows diff, prompts to commit
     
     Recommendation: Start with manual periodic checks, add automation later if needed.
-->

Logseq configuration is split between two locations:
- **Global app settings**: `~/.logseq/` (applies to all graphs)
- **Graph-specific settings**: `~/Logseq/logseq/config.edn` (backed up with graph)

#### Restore Graph from Backup

**If `~/Logseq` doesn't exist** (fresh machine):

<!-- TODO: "Create run_once_025-restore-logseq-if-missing.sh script" -->
<!-- CLAUDE: This script should:
     1. Check if ~/Logseq exists and has content
     2. If not, list available snapshots (daily/weekly/monthly)
     3. Either auto-restore latest daily OR prompt user to choose
     4. Requires: rclone installed, secrets in Keychain
     5. Should run after Phase 4 (after secrets loaded) but before LaunchAgent starts
     
     For now, manual restore instructions:
-->

```bash
# List available snapshots
~/.local/bin/list-logseq

# Restore from most recent daily snapshot
~/.local/bin/restore-logseq daily/latest

# Or restore from specific snapshot
~/.local/bin/restore-logseq daily/YYYY-MM-DD-HHMMSS
```

This restores your entire graph including notes, assets, and graph-specific config.

<!-- TODO: Add Global Logseq Config to chezmoi:
     chezmoi add ~/.logseq/preferences.json
     chezmoi add ~/.logseq/config/config.edn
     chezmoi add ~/.logseq/config/plugins.edn
     Then review with chezmoi diff and commit
-->

<!-- TODO: Add Plugins to chezmoi:
     After trimming unwanted plugins:
     chezmoi add --recursive ~/.logseq/plugins/
     Then commit with message "Add Logseq plugins"
-->

<!-- TODO: Document plugin update workflow (for later reference):
     When installing new plugin: chezmoi add --recursive ~/.logseq/plugins/plugin-name/
     When settings change: chezmoi diff ~/.logseq/plugins/ then chezmoi add --recursive
-->

### 7.3 SSH Keys (if implemented)
<!-- TODO: "We should plan on including SSH config in dotfiles" -->
<!-- CLAUDE: Agreed. Include ~/.ssh/config via chezmoi.
     
     Typical structure:
     - chezmoi add ~/.ssh/config
     - Config can include: Host aliases, User settings, IdentityFile paths, etc.
     
     The actual private keys (~/.ssh/id_ed25519) should NOT be in chezmoi.
     Only the config file that references them.
     
     For multi-machine: Could use chezmoi templates to customize per machine.
-->
<!-- TODO: "Is there a way to programatically/script-based add the SSH key to github? Should gh be part of the brew install? Is this key intended to identify this computer to github only, or would it be used for other (as yet unspecified) authentication (like some vps's)?" -->
<!-- CLAUDE: Yes! GitHub CLI (`gh`) can add SSH keys programmatically:
     
     Command: gh ssh-key add ~/.ssh/id_ed25519.pub --title "MacBook Pro - 2025"
     
     Prerequisites:
     - gh must be installed (add to Brewfile: `brew install gh`)
     - Must authenticate gh first: `gh auth login`
     
     The SSH key serves multiple purposes:
     1. GitHub authentication (clone, push, pull private repos)
     2. SSH to VPS/servers (add public key to ~/.ssh/authorized_keys on servers)
     3. Any SSH-based auth (other git servers like GitLab, Bitbucket)
     4. Commit signing (newer alternative to GPG)
     
     It's a general identity key for this machine, not just GitHub-specific.
     Common practice: One key per machine, add to all services that need it.
     
     Workflow:
     1. Generate key with run_once script
     2. Authenticate gh CLI (might need manual login)
     3. Upload key to GitHub via gh CLI
     4. Same public key can be manually added to VPS authorized_keys as needed
-->
<!-- TODO: "I think we should mark this section with a TODO as there is a lot more to learn and discuss." -->
<!-- CLAUDE: Agreed - SSH key management deserves careful planning:
     
     Topics to research/decide:
     - Key generation: ed25519 vs RSA? Passphrase or not?
     - gh auth: How to handle initial login (requires browser/token)
     - Key backup: How to securely backup private keys?
     - Key rotation: Policy for generating new keys periodically?
     - Multiple machines: Separate keys per machine or shared?
     - Commit signing: SSH vs GPG signing?
     
     This is substantial enough to warrant its own design doc or section.
-->

If dotfiles include SSH config:

```bash
# Generate new SSH key
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/id_ed25519

# Add to ssh-agent
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# Copy public key to add to GitHub/GitLab
pbcopy < ~/.ssh/id_ed25519.pub
```

Add to GitHub: **Settings → SSH and GPG keys → New SSH key**

### 7.4 Custom Python Utilities

**Prerequisites:**
- pipx installed (via Homebrew in Phase 5)
- SSH keys set up (for private repositories)

These utility scripts are installed via pipx for isolated, global access.

**Installation:**

During `chezmoi apply`, the `run_once_060-install-python-utilities.sh` script automatically installs:

1. **toggl-to-zoho** (public): Converts Toggl time tracking CSV exports to Zoho Books format
   - Repository: https://github.com/natecostello/util-toggl-to-zoho
   - Command: `toggl-to-zoho input.csv output.csv`

2. **priv-allocate** (private): Private allocation utility
   - Repository: https://github.com/natecostello/util-priv-allocate (requires SSH access)
   - Command: `priv-allocate` (see repo for usage)

**Manual Installation (if needed):**

```bash
# Install toggl-to-zoho
pipx install git+https://github.com/natecostello/util-toggl-to-zoho.git

# Install priv-allocate (requires SSH key with GitHub access)
pipx install git+ssh://git@github.com/natecostello/util-priv-allocate.git
```

**Verify Installation:**

```bash
# Check commands are available
which toggl-to-zoho
which priv-allocate

# Check versions/help
toggl-to-zoho --version
priv-allocate --help
```

**Upgrading:**

```bash
# Upgrade individual utility
pipx upgrade toggl-to-zoho
pipx upgrade priv-allocate

# Upgrade all pipx packages
pipx upgrade-all
```

**Uninstalling:**

```bash
pipx uninstall toggl-to-zoho
pipx uninstall priv-allocate
```

### 7.5 Git Configuration (already applied)
<!-- TODO: "Should we consider signing commits? What key is used for that? Does setup for that belong here?" -->
<!-- CLAUDE: Yes, commit signing is good practice, especially for open source.
     
     Two options:
     
     1. SSH Signing (Recommended - Simpler):
        - Uses the same SSH key you already have (id_ed25519)
        - GitHub supports this natively (since 2021)
        - Setup in .gitconfig:
          [gpg]
              format = ssh
          [user]
              signingkey = ~/.ssh/id_ed25519.pub
          [commit]
              gpgsign = true
          [tag]
              gpgsign = true
     
     2. GPG Signing (Traditional - More complex):
        - Requires generating separate GPG key
        - More setup, key management more complex
        - Widely supported but overkill for most use cases
     
     Recommendation: Use SSH signing. Add the config above to your .gitconfig template.
     
     To upload SSH signing key to GitHub (different from auth key upload):
       gh ssh-key add ~/.ssh/id_ed25519.pub --type signing --title "MacBook Pro Signing Key"
     
     Or manually: GitHub → Settings → SSH and GPG keys → New SSH key → Key type: Signing Key
     
     Yes, this belongs in section 7.3 (Git Configuration).
-->

Your `.gitconfig` is already in place. Verify:

```bash
git config --global user.name
git config --global user.email
```

### 7.6 VS Code (if implemented)
<!-- TODO: "I would like to figure out how to capture and control VS Code settings via chezmoi." -->
<!-- CLAUDE: Two approaches, both valid:
     
     Option 1: VS Code Settings Sync (Easiest, Recommended):
     - Built into VS Code (Gear icon → Turn on Settings Sync)
     - Syncs via GitHub/Microsoft account
     - Includes: Settings, extensions, keybindings, UI state
     - Automatically syncs across machines
     - No chezmoi needed for this
     - Downside: Not in your dotfiles repo, dependent on external service
     
     Option 2: Manual Management via chezmoi:
     - VS Code settings location (macOS):
       ~/Library/Application Support/Code/User/settings.json
       ~/Library/Application Support/Code/User/keybindings.json
     
     - Extensions list: code --list-extensions > extensions.txt
     
     - Manage with chezmoi:
       chezmoi add ~/Library/Application\ Support/Code/User/settings.json
       chezmoi add ~/Library/Application\ Support/Code/User/keybindings.json
     
     - Install extensions via run_once script:
       while read ext; do code --install-extension "$ext"; done < extensions.txt
     
     - Downsides: More manual, need to remember to update when you change settings
     
     Hybrid Approach (Best of both):
     - Use Settings Sync for day-to-day syncing
     - Also keep settings.json in chezmoi as backup/documentation
     - Run_once script to install critical extensions
     
     Recommendation: Start with Settings Sync (easiest), then add manual backup later if desired.
-->

If using Settings Sync or manual config:

1. Open VS Code
2. Sign in with GitHub
3. Settings Sync should pull extensions and settings
4. Or manually install key extensions: `code --install-extension <ext>`

---

## Phase 8: System Tweaks (if implemented)

If you've added a `run_once_*` script for `defaults write`:

```bash
# Examples of common tweaks (implement as needed):

# Show hidden files in Finder
defaults write com.apple.finder AppleShowAllFiles -bool true

# Disable press-and-hold for keys (enables key repeat)
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Set fast key repeat rate
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15

# Show full path in Finder title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Restart affected apps
killall Finder
```

---

## Phase 9: Verification Checklist

Go through this list to ensure everything is working:

- [ ] **Shell**: zsh with Powerlevel10k prompt displays correctly
- [ ] **Git**: `git config --global --list` shows your name/email
- [ ] **SSH**: `ssh -T git@github.com` authenticates (if keys set up)
- [ ] **Python**: `python --version` shows correct version
- [ ] **Homebrew**: `brew doctor` reports no issues
- [ ] **iTerm2**: Shell integration works (Cmd+Shift+A to jump between prompts)
- [ ] **Logseq backup**: LaunchAgent loaded, manual test successful
- [ ] **Secrets**: All needed items in Keychain
- [ ] **Scripts**: `~/.local/bin/*` executables work
- [ ] **Python utilities**: `toggl-to-zoho --version` and `priv-allocate --help` work
- [ ] **VS Code**: Extensions installed and settings synced (if applicable)

---

## Secret Inventory

These secrets must exist in LastPass **before** running `chezmoi apply`:

| LastPass Item Name              | Type     | Used By                      | Location in Keychain After Bootstrap |
|---------------------------------|----------|------------------------------|--------------------------------------|
| `rclone/logseq_crypt_passphrase`| Password | Logseq backup encryption     | `rclone/logseq/crypt_passphrase`     |
| `rclone/dropbox_token`          | Note     | Dropbox API access           | `rclone/logseq/dropbox_token`        |

### Creating Secrets in LastPass

**For rclone passphrase:**
1. LastPass → Add Item → Secure Note
2. Name: `rclone/logseq_crypt_passphrase`
3. Set a strong password (save in password field, not notes)
4. Save

**For Dropbox token:**
1. Get token from Dropbox: https://www.dropbox.com/developers/apps
2. Create new app → Scoped access → Full Dropbox → Name it
3. Settings → Generated access token → Generate
4. Copy the JSON token
5. LastPass → Add Item → Secure Note
6. Name: `rclone/dropbox_token`
7. Paste JSON in Notes field
8. Save

---

## Troubleshooting

### "lpass: command not found"
- LastPass CLI not installed or not in PATH
- Fix: `brew install lastpass-cli`, then restart terminal

### "chezmoi: command not found"
- chezmoi not installed or not in PATH
- Fix: `brew install chezmoi`, ensure Homebrew is in PATH

### "Bootstrap failed: 5: Input/output error" (LaunchAgent)
- Agent already loaded with old config
- Fix:
  ```bash
  launchctl bootout gui/$(id -u)/com.ncos.backup-logseq
  launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.ncos.backup-logseq.plist
  ```

### "rclone: command not found" in LaunchAgent logs
- PATH not set correctly in LaunchAgent (should be fixed by plist EnvironmentVariables)
- Verify: Check `~/Library/LaunchAgents/com.ncos.backup-logseq.plist` has `EnvironmentVariables` section

### Run-once script failed during chezmoi apply
- Check what script failed: `chezmoi state dump`
- Re-run manually to see detailed error: `~/.local/share/chezmoi/run_once_*.sh`
- Fix issue, then: `chezmoi apply --force`

### Powerlevel10k prompt looks broken
- Missing Nerd Font
- Fix: Install MesloLGS NF from https://github.com/romkatv/powerlevel10k#fonts
- Configure terminal to use it: Preferences → Profiles → Text → Font

### Python version wrong after pyenv setup
- Shell not reloaded after applying dotfiles
- Fix: `source ~/.zshrc` or restart terminal

### Keychain prompts every time for rclone secrets
- Secrets not marked for always-allow access
- Fix: Open Keychain Access, find items, double-click, Access Control → Allow all applications

---

## Post-Bootstrap Tasks

After completing bootstrap, consider:

1. **Backup this machine's Recovery Key** (if FileVault enabled)
   - System Settings → Privacy & Security → FileVault → Recovery Key
   - Store securely (printed paper, password manager)

2. **Enable Time Machine** (local backups)
   - System Settings → General → Time Machine
   - Add backup disk

3. **Install additional apps** not in Homebrew
   - App Store apps
   - Manual downloads

4. **Configure app-specific settings**
   - Dropbox: Sign in, choose folders to sync
   - Logseq: Point to ~/Logseq graph
   - Browser: Sign in, install extensions

5. **Test disaster recovery**
   - Verify you can restore from backup
   - Document any manual steps needed

---

## Updating Dotfiles Later

When you make changes to dotfiles:

```bash
# Edit files in the chezmoi source directory
cd ~/.local/share/chezmoi
chezmoi edit ~/.zshrc

# Or edit directly and add
vim ~/.zshrc
chezmoi add ~/.zshrc

# Review changes before applying
chezmoi diff

# Apply changes
chezmoi apply

# Commit and push
cd ~/.local/share/chezmoi
git add .
git commit -m "Update zshrc"
git push
```

---

## Re-running Bootstrap (Disaster Recovery)

If you need to set up another machine or rebuild:

1. Follow this guide from the top
2. Most run-once scripts are idempotent (safe to re-run)
3. If something fails, use `chezmoi apply --force` to re-run
4. LaunchAgents: unload before reloading if already present

---

## Getting Help

- **chezmoi docs**: https://www.chezmoi.io/
- **Homebrew docs**: https://docs.brew.sh/
- **Check logs**: `~/Library/Logs/` for LaunchAgent output
- **chezmoi state**: `chezmoi doctor` for diagnostics

---

**Last updated:** October 14, 2025
