import ArgumentParser
import Foundation

/// Represents a file with an icon and color coding.
struct FileRepresentation {
  let icon: String
  let color: String
}

/// Stores display options for listing files.
struct DisplayOptions {
  var location: URL?
  var all = false
  var long = false
  var recurse = false
  var color = false
  var icons = false
  var oneLine = false
  var sortBy: SortOption = .name
}

/// Enum defining sorting options.
enum SortOption: String, ExpressibleByArgument {
  case name, time, size
}

/// Enum defining terminal color codes.
enum TerminalColors: String {
  case white = "\u{001B}[0;37m"
  case yellow = "\u{001B}[0;33m"
  case red = "\u{001B}[0;31m"
  case blue = "\u{001B}[0;34m"
  case reset = "\u{001B}[0;0m"
}

/// A helper class to manage file system operations.
class FileManagerHelper {
  static var fm: FileManager { FileManager() }

  /// Determines the type of a file and returns its representation.
  /// - Parameters:
  ///   - location: The file URL.
  ///   - attributes: The file attributes.
  /// - Returns: A `FileRepresentation` object containing the icon and color.
  static func determineType(of location: URL, attributes: [FileAttributeKey: Any]) -> FileRepresentation {
    if location.hasDirectoryPath {
      return FileRepresentation(icon: "📁", color: TerminalColors.blue.rawValue)
    }

    if fm.isExecutableFile(atPath: location.path) {
      return FileRepresentation(icon: "⚙️", color: TerminalColors.red.rawValue)
    }

    if let fileType = attributes[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
      if let destination = try? fm.destinationOfSymbolicLink(atPath: location.path),
        fm.fileExists(atPath: destination, isDirectory: nil)
      {
        return FileRepresentation(icon: "🔗", color: TerminalColors.yellow.rawValue)
      }
    }

    return FileRepresentation(icon: "📄", color: TerminalColors.white.rawValue)
  }

  /// Retrieves and formats file attributes for display.
  /// - Parameters:
  ///   - location: The file URL.
  ///   - opts: The display options.
  /// - Throws: An error if file attributes cannot be retrieved.
  /// - Returns: A formatted string of file attributes.
  static func getFileAttributes(at location: URL, with opts: DisplayOptions) throws -> String {
    let attributes = try fm.attributesOfItem(atPath: location.path)
    let fileRepresentation = (opts.color || opts.icons) ? determineType(of: location, attributes: attributes) : nil
    var attributesString = ""

    if let fileRep = fileRepresentation, opts.icons {
      attributesString.append(fileRep.icon + " ")
    }

    if opts.long {
      if let permissions = attributes[.posixPermissions] as? Int {
        attributesString.append(String(permissions) + " ")
      }
      if let owner = attributes[.ownerAccountName] as? String {
        attributesString.append(owner + " ")
      }
      if let group = attributes[.groupOwnerAccountName] as? String {
        attributesString.append(group + " ")
      }
      if let refCount = attributes[.referenceCount] as? Int {
        attributesString.append(String(format: "%-2d", refCount) + " ")
      }
      if let fileSize = attributes[.size] as? Int {
        let byteFormatter = ByteCountFormatter()
        byteFormatter.allowedUnits = [.useKB, .useMB, .useGB]
        byteFormatter.countStyle = .file
        attributesString.append(byteFormatter.string(fromByteCount: Int64(fileSize)) + " ")
      }
      if let modificationDate = attributes[.modificationDate] as? Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        attributesString.append(dateFormatter.string(from: modificationDate) + " ")
      }
    }

    if opts.color, let fileRep = fileRepresentation {
      attributesString.append(fileRep.color)
    }
    attributesString.append(location.lastPathComponent)
    if opts.color {
      attributesString.append(TerminalColors.reset.rawValue)
    }

    if opts.oneLine || opts.long {
      attributesString.append("\n")
    } else {
      attributesString.append("  ")
    }

    return attributesString
  }

  /// Retrieves and formats the contents of a directory.
  /// - Parameter opts: The display options.
  /// - Throws: An error if the directory contents cannot be retrieved.
  /// - Returns: A formatted string listing the directory contents.
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

      for url in contents where url.hasDirectoryPath {
        result.append("\n\(url.relativePath):\n")
        var newOpts = opts
        newOpts.location = url
        result.append(try findContents(with: newOpts))
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

  /// Executes the command with the specified options.
  /// - Throws: An error if listing files fails.
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
