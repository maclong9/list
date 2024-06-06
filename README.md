# SwiftList

A simple rebuild of the `ls` UNIX command in Swift.

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
