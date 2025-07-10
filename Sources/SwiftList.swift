import ArgumentParser
import Foundation

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

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
  var humanReadable = false
  var directoryOnly = false
  var classify = false
  var header = false
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
  static var fileManager: FileManager { FileManager() }

  /// Returns the terminal width in characters.
  private static func terminalWidth() -> Int {
    var w = winsize()
    guard ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 else { return 80 }
    return Int(w.ws_col)
  }

  /// Determines the type of a file and returns its representation.
  /// - Parameters:
  ///   - location: The file URL.
  ///   - attributes: The file attributes.
  /// - Returns: A `FileRepresentation` object containing the icon and color.
  static func determineType(
    of location: URL, attributes: [FileAttributeKey: Any]
  )
    -> FileRepresentation
  {
    if location.hasDirectoryPath {
      return FileRepresentation(icon: "📁", color: TerminalColors.blue.rawValue)
    }

    if fileManager.isExecutableFile(atPath: location.path) {
      return FileRepresentation(icon: "⚙️", color: TerminalColors.red.rawValue)
    }

    if let fileType = attributes[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
      if let destination = try? fileManager.destinationOfSymbolicLink(atPath: location.path),
        fileManager.fileExists(atPath: destination, isDirectory: nil)
      {
        return FileRepresentation(icon: "🔗", color: TerminalColors.yellow.rawValue)
      }
    }

    return FileRepresentation(icon: "📄", color: TerminalColors.white.rawValue)
  }

  /// Retrieves and formats file attributes for display.
  /// - Parameters:
  ///   - location: The file URL.
  ///   - options: The display options.
  /// - Throws: An error if file attributes cannot be retrieved.
  /// - Returns: A formatted string of file attributes.
  static func fileAttributes(at location: URL, with options: DisplayOptions) throws -> String {
    let attributes = try fileManager.attributesOfItem(atPath: location.path)
    let fileRepresentation =
      (options.color || options.icons) ? determineType(of: location, attributes: attributes) : nil
    var attributesString = ""

    if let fileRep = fileRepresentation, options.icons {
      attributesString.append(fileRep.icon)
      attributesString.append(" ")
    }

    if options.long {
      if let permissions = attributes[.posixPermissions] as? Int {
        attributesString.append(String(permissions))
        attributesString.append(" ")
      }
      if let owner = attributes[.ownerAccountName] as? String {
        attributesString.append(owner)
        attributesString.append(" ")
      }
      if let group = attributes[.groupOwnerAccountName] as? String {
        attributesString.append(group)
        attributesString.append(" ")
      }
      if let refCount = attributes[.referenceCount] as? Int {
        attributesString.append(String(format: "%-2d", refCount))
        attributesString.append(" ")
      }
      if let fileSize = attributes[.size] as? Int {
        let byteFormatter = ByteCountFormatter()
        if options.humanReadable {
          byteFormatter.allowedUnits = [.useKB, .useMB, .useGB, .useTB]
          byteFormatter.countStyle = .file
        } else {
          byteFormatter.allowedUnits = [.useBytes]
          byteFormatter.countStyle = .file
        }
        attributesString.append(byteFormatter.string(fromByteCount: Int64(fileSize)))
        attributesString.append(" ")
      }
      if let modificationDate = attributes[.modificationDate] as? Date {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        attributesString.append(dateFormatter.string(from: modificationDate))
        attributesString.append(" ")
      }
    }

    if options.color, let fileRep = fileRepresentation {
      attributesString.append(fileRep.color)
    }

    var fileName = location.lastPathComponent
    if options.classify {
      if location.hasDirectoryPath {
        fileName += "/"
      } else if fileManager.isExecutableFile(atPath: location.path) {
        fileName += "*"
      }
    }

    attributesString.append(fileName)
    if options.color {
      attributesString.append(TerminalColors.reset.rawValue)
    }

    if options.oneLine || options.long {
      attributesString.append("\n")
    } else {
      attributesString.append("  ")
    }

    return attributesString
  }

  /// Retrieves and formats the contents of a directory.
  /// - Parameter options: The display options.
  /// - Throws: An error if the directory contents cannot be retrieved.
  /// - Returns: A formatted string listing the directory contents.
  static func contents(with options: DisplayOptions) throws -> String {
    var result = ""

    let targetURL = options.location ?? URL(fileURLWithPath: fileManager.currentDirectoryPath)
    
    // Add column header if requested and in long format
    if options.header && options.long {
      result.append("Permissions Owner Group Links Size          Date            Time  Name\n")
      result.append("────────────────────────────────────────────────────────────────────────────\n")
    }

    // Handle directory-only option
    if options.directoryOnly {
      result.append(try fileAttributes(at: targetURL, with: options))
      return result
    }

    let contents = try fileManager.contentsOfDirectory(
      at: targetURL,
      includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
      options: options.all ? [] : [.skipsHiddenFiles]
    )

    // Sort contents based on sort option
    let sortedContents = contents.sorted { url1, url2 in
      switch options.sortBy {
      case .name:
        return url1.lastPathComponent.localizedCompare(url2.lastPathComponent) == .orderedAscending
      case .time:
        let date1 = try? url1.resourceValues(forKeys: [.contentModificationDateKey])
          .contentModificationDate
        let date2 = try? url2.resourceValues(forKeys: [.contentModificationDateKey])
          .contentModificationDate
        return (date1 ?? Date.distantPast) > (date2 ?? Date.distantPast)
      case .size:
        let size1 = try? url1.resourceValues(forKeys: [.fileSizeKey]).fileSize
        let size2 = try? url2.resourceValues(forKeys: [.fileSizeKey]).fileSize
        return (size1 ?? 0) > (size2 ?? 0)
      }
    }

    // Handle terminal width wrapping for non-long format
    if !options.long && !options.oneLine {
      let width = terminalWidth()
      var currentLineLength = 0

      for url in sortedContents {
        let fileString = try fileAttributes(at: url, with: options)
        let fileLength = fileString.replacingOccurrences(
          of: "\u{001B}\\[[0-9;]*m", with: "", options: .regularExpression
        ).count

        if currentLineLength + fileLength > width && currentLineLength > 0 {
          result.append("\n")
          currentLineLength = 0
        }

        result.append(fileString)
        currentLineLength += fileLength
      }
    } else {
      for url in sortedContents {
        result.append(try fileAttributes(at: url, with: options))
      }
    }

    if options.recurse {
      if !options.oneLine && !options.long {
        result.append("\n")
      }

      for url in sortedContents where url.hasDirectoryPath {
        result.append("\n\(url.relativePath):\n")
        var newOptions = options
        newOptions.location = url
        result.append(try FileManagerHelper.contents(with: newOptions))
      }
    }

    return result
  }
}

@main
struct sls: ParsableCommand {
  static let configuration = CommandConfiguration(
    version: "1.2.2"
  )
  
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

  @Flag(name: [.customShort("1")], help: "Force one file per line.")
  var oneColumn = false

  @Flag(name: .long, help: "Display column headers explaining the output format.")
  var header = false

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
      oneLine: oneLine || oneColumn,
      humanReadable: humanReadable,
      directoryOnly: directory,
      classify: classify,
      header: header,
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
