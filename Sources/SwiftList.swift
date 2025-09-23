import ArgumentParser
import Configuration
import Foundation
import Models
import Utilities

@main
struct List: ParsableCommand {
    static let configuration = CommandConfiguration(
        version: "1.3.0"
    )

    @Flag(name: .shortAndLong, help: "Display all files, including hidden.")
    var all = false

    @Flag(
        name: .shortAndLong,
        help:
            "Display file attributes, one file per line. Columns: permissions, owner, group, links, size, date, time, name"
    )
    var long = false

    @Flag(name: .shortAndLong, help: "Recurse into directories.")
    var recurse = false

    @Flag(name: .shortAndLong, help: "Colorize the output.")
    var color = false

    @Flag(name: .shortAndLong, help: "Display icons denoting file type.")
    var icons = false

    @Flag(name: .shortAndLong, help: "Display each file on its own line.")
    var oneLine = false

    @Flag(name: .long, help: "Display human readable file sizes.")
    var humanReadable = false

    @Flag(name: [.customShort("t"), .long], help: "Sort by modification time.")
    var sortTime = false

    @Flag(name: [.customShort("S"), .long], help: "Sort by file size.")
    var sortSize = false

    @Flag(name: .shortAndLong, help: "List directories themselves, not their contents.")
    var directory = false

    @Flag(name: [.customShort("F"), .long], help: "Append indicator (/, *, etc.) to entries.")
    var classify = false

    @Argument(help: "List files at one or more paths, omit for current directory.")
    var paths: [String] = []

    /// Executes the command with the specified options.
    /// - Throws: An error if listing files fails.
    func run() throws {
        // Determine sort option
        var sortBy: SortOption = .name
        if sortTime {
            sortBy = .time
        } else if sortSize {
            sortBy = .size
        }

        let options = DisplayOptions(
            all: all,
            long: long,
            recurse: recurse,
            color: color,
            icons: icons,
            oneLine: oneLine,
            humanReadable: humanReadable,
            directoryOnly: directory,
            classify: classify,
            sortBy: sortBy
        )

        if paths.isEmpty {
            var opts = options
            opts.location = URL(fileURLWithPath: FileManager().currentDirectoryPath)
            print(try FileManagerHelper.contents(with: opts))
        } else {
            for (index, path) in paths.enumerated() {
                var opts = options
                opts.location = URL(fileURLWithPath: path)
                if paths.count > 1 {
                    if index > 0 {
                        print()
                    }
                    print("\(path):")
                }
                print(try FileManagerHelper.contents(with: opts))
            }
        }
    }
}
