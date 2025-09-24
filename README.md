# SwiftList

[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaclong9%2Flist%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maclong9/list)

A simple and fast rebuild of the UNIX `ls` command.

<img width="835" height="1018" alt="Screenshot 2025-07-11 at 12 40 58" src="https://github.com/user-attachments/assets/823505e9-ad33-4e0d-8251-3ef47d48c931" />

## Installation

### Download Pre-built Binaries
Download the latest release for your architecture:

**macOS Apple Silicon (M Series):**
```sh
sudo mkdir -p /usr/local/bin
sudo curl -L $(curl -s https://api.github.com/repos/maclong9/list/releases/latest | grep "browser_download_url.*sls-aarch64" | cut -d\" -f4) -o /usr/local/bin/sls
sudo chmod +x /usr/local/bin/sls
```

**Manual Download:**
Visit the [releases page](https://github.com/maclong9/list/releases) and download `sls-aarch64` (Apple Silicon) or `sls-x86_64` (Intel) directly.

### With mise
```sh
mise settings experimental true
mise install spm:maclong9/swift-list
```

### Shell Completion
Generate completion scripts:
```sh
# Bash
sls --generate-completion-script bash > ~/.bash_completions/sls.bash

# Zsh
sls --generate-completion-script zsh > ~/.zsh/completion/_sls

# Fish
sls --generate-completion-script fish > ~/.config/fish/completions/sls.fish
```

Install by copying to your shell's completion directory or sourcing in your shell config.

## Usage

```sh
sls [OPTIONS] [<path>]
```

## Options

### Display Options
- `-a, --all` — Display all files, including hidden
- `-l, --long` — Display file attributes, one file per line
- `-o, --one-line` — Display each file on its own line
- `-d, --directory` — List directories themselves, not their contents

### Formatting Options
- `-c, --color` — Colorize the output
- `-i, --icons` — Display icons denoting file type
- `-F, --classify` — Append indicator (/, *, etc.) to entries
- `--human-readable` — Display human readable file sizes (KB, MB, GB)

### Sorting Options
- `-t, --sort-time` — Sort by modification time (newest first)
- `-S, --sort-size` — Sort by file size (largest first)

### Navigation Options
- `-r, --recurse` — Recurse into directories

### Help
- `--help` — Show help information
- `--version` — Display version information

## Common Usage

```sh
# Basic listing
sls

# Detailed view with colors and icons
sls -cli --human-readable

# Show headers for clarity
sls -l --header --human-readable

# Recursive exploration
sls -clir --human-readable

# Sort by time or size
sls -tcli --human-readable    # by time
sls -cliS --human-readable    # by size
```
