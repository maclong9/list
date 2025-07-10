# SwiftList

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaclong9%2Flist%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maclong9/list)

A __simple__ and __fast__ rebuild of the UNIX `ls` command. 

## Installation 

### Manually

``` sh
sudo mkdir -p /usr/local/bin
sudo curl -L $(curl -s https://api.github.com/repos/maclong9/list/releases/latest | grep "browser_download_url.*sls" | cut -d\" -f4) -o /usr/local/bin/sls
sudo chmod +x /usr/local/bin/sls
```

### With mise

First install [mise](https://mise.jdx.dev) then run:

``` sh
mise settings experimental true
mise install spm:maclong9/swift-list
```

> [!NOTE]
> You can also clone the repository and build the package yourself before moving to your executables.

### Shell Completion

Enable shell completion for enhanced productivity with tab completion of commands and options.

#### Generate Completion Scripts

```sh
# For bash
sls --generate-completion-script bash > ~/.bash_completions/sls.bash

# For zsh  
sls --generate-completion-script zsh > ~/.zsh/completion/_sls

# For fish
sls --generate-completion-script fish > ~/.config/fish/completions/sls.fish
```

#### Installation Instructions

**Bash:**
- With bash-completion: Copy to `/usr/local/etc/bash_completion.d/`
- Manual: Source the script in `~/.bashrc` or `~/.bash_profile`

**Zsh:**
- With oh-my-zsh: Copy to `~/.oh-my-zsh/completions/_sls`
- Manual: Add completion directory to `fpath` and enable `compinit` in `~/.zshrc`:
  ```sh
  fpath=(~/.zsh/completion $fpath)
  autoload -U compinit
  compinit
  ```

**Fish:**
- Copy to any directory in `$fish_completion_path`
- Typical location: `~/.config/fish/completions/sls.fish`

## Usage

``` sh
sls [OPTIONS] [<path>]
```

### Options

#### Display Options
- `-a, --all`:               Display all files, including hidden.
- `-l, --long`:              Display file attributes, one file per line
- `-o, --one-line`:          Display each file on its own line.
- `-1`:                      Force one file per line.
- `-d, --directory`:         List directories themselves, not their contents.

#### Formatting Options
- `-c, --color`:             Colorize the output.
- `-i, --icons`:             Display icons denoting file type.
- `-F, --classify`:          Append indicator (/, *, etc.) to entries.
- `--human-readable`:        Display human readable file sizes (KB, MB, GB).
- `--header`:                Display column headers explaining the output format (requires -l).

#### Sorting Options
- `-t, --sort-time`:         Sort by modification time (newest first).
- `-S, --sort-size`:         Sort by file size (largest first).

#### Navigation Options
- `-r, --recurse`:           Recurse into directories.

#### Help
- `--help`:                  Show help information.

### Recommended Usage

#### Quick Overview (Default)
For a quick, clean overview of files and directories:
``` sh
sls
```

#### Detailed View with Colors and Icons
For maximum readability with detailed information:
``` sh
sls -cli --human-readable
```

#### Detailed View with Column Headers
For understanding what each column represents:
``` sh
sls -l --header --human-readable
```

#### Directory Navigation
For exploring directory structures:
``` sh
sls -clir --human-readable
```

#### Time-based Analysis
For viewing recently modified files:
``` sh
sls -clit --human-readable
```

#### Size Analysis
For viewing files by size:
``` sh
sls -cliS --human-readable
```
