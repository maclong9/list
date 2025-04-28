# SwiftList

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaclong9%2Flist%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maclong9/list)
[![Automated Release](https://github.com/maclong9/list/actions/workflows/release.yml/badge.svg)](https://github.com/maclong9/list/actions/workflows/release.yml)

A __simple__ and __fast__ rebuild of the UNIX `ls` command. 

## Installation 

### Manually

``` sh
sudo mkdir -p /usr/local/bin
sudo curl -L $(curl -s https://api.github.com/repos/maclong9/list/releases/latest | grep "browser_download_url.*sls" | cut -d\" -f4) -o /usr/local/bin/sls
sudo chmod +x /usr/local/bin/sls
```

### With Mint

First install [mint](https://github.com/yonaskolb/Mint) then run:

``` sh
mint install maclong9/swift-list
```

> [!NOTE]
> You can also clone the repository and build the package yourself before moving to your executables.

## Usage

``` sh
sls [--all] [--long] [--recurse] [--color] [--icons] [--one-line] [<path>]
```

### Options

- `-a, --all`:               Display all files, including hidden.
- `-l, --long`:              Display file attributes, one file per line
- `-r, --recurse`:           Recurse into directories.
- `-c, --color`:             Colorize the output.
- `-i, --icons`:             Display icons denoting file type.
- `-o, --one-line`:          Display each file on its own line.
- `-h, --help`:              Show help information.

### Recommended Options

These options provide the best readability while still giving detailed information.

``` sh
sls -cli [-ra] [<path>] 
```
