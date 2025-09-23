import Foundation

#if canImport(Darwin)
    import Darwin
#elseif canImport(Glibc)
    import Glibc
#endif

/// A helper class to manage file system operations.
public class FileManagerHelper {
    /// The shared FileManager instance
    public static var fileManager: FileManager { FileManager() }

    /// Returns the terminal width in characters.
    private static func terminalWidth() -> Int {
        var w = winsize()
        guard ioctl(STDOUT_FILENO, UInt(TIOCGWINSZ), &w) == 0 else { return 80 }
        return Int(w.ws_col)
    }

    /// Determines the type of a file and returns its representation.
    /// - Parameters:
    ///   - location: The file URL.
    ///   - attributes: The file attributes.
    /// - Returns: A `FileRepresentation` object containing the icon and color.
    public static func determineType(
        of location: URL, attributes: [FileAttributeKey: Any]
    ) -> FileRepresentation {
        if location.hasDirectoryPath {
            return FileRepresentation(
                icon: "📁", color: TerminalColors.blue.rawValue, destination: nil)
        }

        // Check for symbolic links first, before checking if executable
        if let fileType = attributes[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
            if let destination = try? fileManager.destinationOfSymbolicLink(atPath: location.path) {
                return FileRepresentation(
                    icon: "🔗", color: TerminalColors.yellow.rawValue, destination: destination)
            }
        }

        if fileManager.isExecutableFile(atPath: location.path) {
            return FileRepresentation(
                icon: "⚙️", color: TerminalColors.red.rawValue, destination: nil)
        }

        return FileRepresentation(icon: "📄", color: TerminalColors.white.rawValue, destination: nil)
    }

    /// Retrieves and formats file attributes for display.
    /// - Parameters:
    ///   - location: The file URL.
    ///   - options: The display options.
    /// - Throws: An error if file attributes cannot be retrieved.
    /// - Returns: A formatted string of file attributes.
    public static func fileAttributes(at location: URL, with options: DisplayOptions) throws
        -> String
    {
        // For symbolic links, we need to get the link's own attributes, not the target's
        var attributes: [FileAttributeKey: Any]
        let path = location.path

        // Use lstat equivalent by checking if it's a symbolic link first
        var isSymbolicLink = false
        var statBuffer = stat()
        if lstat(path, &statBuffer) == 0 {
            isSymbolicLink = (statBuffer.st_mode & S_IFMT) == S_IFLNK
        }

        if isSymbolicLink {
            // For symbolic links, get the link's own attributes using URL resource values
            let resourceKeys: [URLResourceKey] = [
                .fileSizeKey, .contentModificationDateKey, .fileResourceTypeKey,
            ]
            let resourceValues = try location.resourceValues(forKeys: Set(resourceKeys))

            // Convert to the expected attribute format
            attributes = [:]
            attributes[.type] = FileAttributeType.typeSymbolicLink
            if let fileSize = resourceValues.fileSize {
                attributes[.size] = fileSize
            }
            if let modificationDate = resourceValues.contentModificationDate {
                attributes[.modificationDate] = modificationDate
            }

            // Get additional attributes that might be available
            do {
                let additionalAttribs = try fileManager.attributesOfItem(atPath: path)
                // Only copy non-conflicting attributes
                for (key, value) in additionalAttribs {
                    if attributes[key] == nil {
                        attributes[key] = value
                    }
                }
            } catch {
                // If we can't get additional attributes, that's fine for broken links
                // Set some default values
                attributes[.posixPermissions] = 0o755
                attributes[.ownerAccountName] = NSUserName()
                attributes[.groupOwnerAccountName] = "wheel"
                attributes[.referenceCount] = 1
            }
        } else {
            attributes = try fileManager.attributesOfItem(atPath: location.path)
        }

        let fileRepresentation = determineType(of: location, attributes: attributes)
        var attributesString = ""

        if options.icons {
            attributesString.append(fileRepresentation.icon)
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

        if options.color {
            attributesString.append(fileRepresentation.color)
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

        // Add symbolic link destination if this is a symbolic link and we have destination info
        if let destination = fileRepresentation.destination {
            attributesString.append(" -> ")
            attributesString.append(destination)
        }
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
    public static func contents(with options: DisplayOptions) throws -> String {
        var result = ""

        let targetURL = options.location ?? URL(fileURLWithPath: fileManager.currentDirectoryPath)

        // Handle directory-only option
        if options.directoryOnly {
            result.append(try fileAttributes(at: targetURL, with: options))
            return result
        }

        let contents = try fileManager.contentsOfDirectory(
            at: targetURL,
            includingPropertiesForKeys: [
                .fileSizeKey, .isDirectoryKey, .contentModificationDateKey,
            ],
            options: options.all ? [] : [.skipsHiddenFiles]
        )

        // Sort contents based on sort option
        let sortedContents = contents.sorted { url1, url2 in
            switch options.sortBy {
                case .name:
                    return url1.lastPathComponent.localizedCompare(url2.lastPathComponent)
                        == .orderedAscending
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
