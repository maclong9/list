import ArgumentParser
import Foundation

let files = FileManager.default

struct FileRepresentation {
  let icon: String
  let color: String
}

struct DisplayOptions {
  let location: URL
  let all: Bool
  let long: Bool
  let recurse: Bool
  let color: Bool
  let icons: Bool
  let oneLine: Bool
}

func getFileAttributes(_ location: URL, with opts: DisplayOptions) throws -> String {
  let fileAttributes = try files.attributesOfItem(atPath: location.path)
  let file = determineType(location)

  return
    "\(opts.icons ? "\(file.icon) " : "")\(opts.color ? file.color : "")\(opts.long ? fileAttributes[.posixPermissions] ?? "" : "") \(opts.long ? fileAttributes[.ownerAccountName] ?? "" : "") \(opts.long ? fileAttributes[.groupOwnerAccountName] ?? "" : "") \(opts.long ? fileAttributes[.size] ?? "" : "") \(opts.long ? fileAttributes[.modificationDate] ?? "" : "") \(location.lastPathComponent)\(opts.oneLine || opts.long ? "\n" : "  ")\(opts.color ? "\u{001B}[0;0m" : "")"
}

func determineType(_ location: URL) -> FileRepresentation {
  if location.hasDirectoryPath {
    return FileRepresentation(icon: "📁", color: "\u{001B}[0;34m")
  }

  if files.isExecutableFile(atPath: location.path) {
    return FileRepresentation(icon: "⚙️", color: "\u{001B}[0;31m ")
  }

  return FileRepresentation(icon: "📃", color: "\u{001B}[0;37m")
}

func findContents(with opts: DisplayOptions) throws -> String {
  var result = ""

  let contents = try files.contentsOfDirectory(
    at: opts.location,
    includingPropertiesForKeys: nil,
    options: opts.all ? [] : [.skipsHiddenFiles]
  )

  for url in contents {
    result += try getFileAttributes(url, with: opts)
  }

  if opts.recurse {
    if !opts.oneLine {
      result += "\n"
    }

    for url in contents {
      if url.hasDirectoryPath {
        result += "\n\(opts.icons ? "📁 " : "./")\(url.lastPathComponent):\n"
        result += try findContents(
          with: DisplayOptions(
            location: url,
            all: opts.all,
            long: opts.long,
            recurse: opts.recurse,
            color: opts.color,
            icons: opts.icons,
            oneLine: opts.oneLine
          ))
      }
    }
  }

  return result
}

@main
struct SwiftList: ParsableCommand {
  @Flag(name: .shortAndLong, help: "Display all files, including hidden.")
  var all = false
  @Flag(name: .shortAndLong, help: "Display extended details and attributes.")
  var long = false
  @Flag(name: .shortAndLong, help: "Recurse into directories.")
  var recurse = false
  @Flag(name: .shortAndLong, help: "Colorize the output.")
  var color = false
  @Flag(name: .shortAndLong, help: "Display each file on its own line.")
  var oneLine = false
  @Flag(name: .shortAndLong, help: "Display icons denoting file type.")
  var icons = false
  @Argument(help: "List files at path, omit for current directory.")
  var path: String?

  func run() throws {
    let location = URL(fileURLWithPath: path ?? files.currentDirectoryPath)
    let result = try findContents(
      with: DisplayOptions(
        location: location,
        all: all,
        long: long,
        recurse: recurse,
        color: color,
        icons: icons,
        oneLine: oneLine
      ))

    print(result)
  }
}
