import ArgumentParser
import Foundation

struct FileRepresentation {
  let icon: String
  let color: String
}

struct DisplayOptions {
  var location: URL?
  let all: Bool
  let long: Bool
  let recurse: Bool
  let color: Bool
  let icons: Bool
  let oneLine: Bool
}

enum TerminalColors: String {
  case white = "\u{001B}[0;37m"
  case yellow = "\u{001B}[0;33m"
  case red = "\u{001B}[0;31m"
  case blue = "\u{001B}[0;34m"
  case reset = "\u{001B}[0;0m"
}

let files = FileManager.default

class FileManagerHelper {
  static let fm = FileManager.default

  static func determineType(of location: URL) throws -> FileRepresentation {
    if location.hasDirectoryPath {
      return FileRepresentation(icon: "📁", color: TerminalColors.blue.rawValue)
    }

    if fm.isExecutableFile(atPath: location.path) {
      return FileRepresentation(icon: "⚙️ ", color: TerminalColors.red.rawValue)
    }

    let attributes = try fm.attributesOfItem(atPath: location.path)
    if let fileType = attributes[FileAttributeKey.type] as? FileAttributeType {
      if fileType == .typeSymbolicLink {
        return FileRepresentation(icon: "🔗", color: TerminalColors.yellow.rawValue)
      }
    }

    return FileRepresentation(icon: "📃", color: TerminalColors.white.rawValue)
  }

  static func getFileAttributes(at location: URL, with opts: DisplayOptions) throws -> String {
    let attributes = try fm.attributesOfItem(atPath: location.path)
    let fileRepresentation: FileRepresentation? = opts.color || opts.icons ? try determineType(of: location) : nil
    var attributesString = ""

    if opts.icons {
      attributesString.append(fileRepresentation!.icon + " ")
    }

    if opts.long {
      attributesString.append(String(attributes[.posixPermissions] as! Int) + " ")
      attributesString.append(attributes[.ownerAccountName] as! String + " ")
      attributesString.append(attributes[.groupOwnerAccountName] as! String + " ")
      attributesString.append(String(attributes[.referenceCount] as! Int) + " ")
      attributesString.append(String(format: "%-4d", attributes[.size] as! Int) + " ")

      if let modificationDate = attributes[.modificationDate] as? Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM HH:mm"
        attributesString.append(dateFormatter.string(from: modificationDate) + " ")
      }
    }

    if opts.color {
      attributesString.append(fileRepresentation!.color)
      attributesString.append(location.lastPathComponent)
      attributesString.append(TerminalColors.reset.rawValue)
    } else {
      attributesString.append(location.lastPathComponent)
    }

    if opts.oneLine || opts.long {
      attributesString.append("\n")
    } else {
      attributesString.append("  ")
    }

    return attributesString
  }

  static func findContents(with opts: DisplayOptions) throws -> String {
    var result = ""

    let contents = try fm.contentsOfDirectory(
      at: opts.location ?? URL(fileURLWithPath: fm.currentDirectoryPath),
      includingPropertiesForKeys: nil,
      options: opts.all ? [] : [.skipsHiddenFiles]
    )

    for url in contents {
      result.append(try getFileAttributes(at: url, with: opts))
    }

    if opts.recurse {
      if !opts.oneLine || !opts.long {
        result.append("\n")
      }

      for url in contents {
        if url.hasDirectoryPath {
          result.append("\n\(opts.icons ? "📁 " : "")\(url.relativePath):\n")
          var newOpts = opts
          newOpts.location = url
          result.append(try findContents(with: newOpts))
        }
      }
    }

    return result
  }
}

@main
struct sls: ParsableCommand {
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
  @Flag(name: .shortAndLong, help: "Display each file on its own line.")
  var oneLine = false
  @Argument(help: "List files at path, omit for current directory.")
  var path: String?

  func run() throws {
    print(
      try FileManagerHelper.findContents(
        with: DisplayOptions(
          location: path != nil ? URL(fileURLWithPath: path!) : nil,
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
