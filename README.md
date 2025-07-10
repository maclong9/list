# SwiftList

[![Swift Package Index](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaclong9%2Flist%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maclong9/list)

A simple and fast rebuild of the UNIX `ls` command.

## Installation

### Manual Install
```sh
sudo mkdir -p /usr/local/bin
sudo curl -L $(curl -s https://api.github.com/repos/maclong9/list/releases/latest | grep "browser_download_url.*sls" | cut -d\" -f4) -o /usr/local/bin/sls
sudo chmod +x /usr/local/bin/sls
```

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

### Options

**Display**: `-a` (all), `-l` (long), `-o` (one-line), `-1` (force one-line), `-d` (directory)  
**Format**: `-c` (color), `-i` (icons), `-F` (classify), `--human-readable`, `--header`  
**Sort**: `-t` (time), `-S` (size)  
**Navigate**: `-r` (recurse)  
**Help**: `--help`, `-v` (version)

### Common Usage

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
sls -clit --human-readable    # by time
sls -cliS --human-readable    # by size
```
