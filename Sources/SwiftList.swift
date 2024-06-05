import ArgumentParser
import Foundation

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

let files = FileManager.default

class FileManagerHelper {
  static let fm = FileManager.default

  static func determineType(_ location: URL) -> FileRepresentation {
    if location.hasDirectoryPath {
      return FileRepresentation(icon: "📁", color: "\u{001B}[0;34m")
    }

    if fm.isExecutableFile(atPath: location.path) {
      return FileRepresentation(icon: "⚙️ ", color: "\u{001B}[0;31m")
    }

    return FileRepresentation(icon: "📃", color: "\u{001B}[0;37m")
  }

  static func getFileAttributes(_ location: URL, with opts: DisplayOptions) throws -> String {
    var result = ""
    let fileAttributes = try fm.attributesOfItem(atPath: location.path)
    let file = determineType(location)

    if opts.icons {
      result.append(file.icon + " ")
    }

    if opts.long {
      result.append(String(fileAttributes[.posixPermissions] as! Int) + " ")
      result.append(fileAttributes[.ownerAccountName] as! String + " ")
      result.append(fileAttributes[.groupOwnerAccountName] as! String + " ")
      result.append(String(format: "%-4d", fileAttributes[.size] as! Int) + " ")

      if let modificationDate = fileAttributes[.modificationDate] as? Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM HH:mm"
        result.append(dateFormatter.string(from: modificationDate) + " ")
      }
    }

    if opts.color {
      result.append(file.color)
      result.append(location.lastPathComponent)
      result.append("\u{001B}[0;0m")
    } else {
      result.append(location.lastPathComponent)
    }

    if opts.oneLine || opts.long {
      result.append("\n")
    } else {
      result.append("  ")
    }

    return result
  }

  static func findContents(with opts: DisplayOptions) throws -> String {
    var result = ""

    let contents = try fm.contentsOfDirectory(
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
}

@main
struct SwiftList: ParsableCommand {
  @Flag(name: .shortAndLong, help: "Display all files, including hidden.")
  var all = false
  @Flag(name: .shortAndLong, help: "Display file attributes, one file per line")
  var long = false
  @Flag(name: .shortAndLong, help: "Recurse into directories.")
  var recurse = false
  @Flag(name: .shortAndLong, help: "Colorize the output.")
  var color = false
  @Flag(name: .shortAndLong, help: "Display icons denoting file type.")
  var icons = false
  @Argument(help: "List files at path, omit for current directory.")
  var path: String?
  @Flag(name: .shortAndLong, help: "Display each file on its own line.")
  var oneLine = false

  func run() throws {
    print(
      try FileManagerHelper.findContents(
        with: DisplayOptions(
          location: URL(fileURLWithPath: path ?? FileManagerHelper.fm.currentDirectoryPath),
          all: all,
          long: long,
          recurse: recurse,
          color: color,
          icons: icons,
          oneLine: oneLine
        )
      )
    )
  }
}
