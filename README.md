# SwiftList

 [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmaclong9%2Fswift-list%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/maclong9/swift-list)

A __simple__ and __fast__ rebuild of the UNIX `ls` command.

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
