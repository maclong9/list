import Foundation

/// Represents a file with an icon and color coding.
public struct FileRepresentation {
    /// The icon representing the file type
    public let icon: String

    /// The ANSI color code for the file type
    public let color: String

    /// The destination path for symbolic links, nil for non-symbolic link files
    public let destination: String?

    /// Creates a new FileRepresentation instance
    /// - Parameters:
    ///   - icon: The icon representing the file type
    ///   - color: The ANSI color code for the file type
    ///   - destination: The destination path for symbolic links (optional)
    public init(icon: String, color: String, destination: String? = nil) {
        self.icon = icon
        self.color = color
        self.destination = destination
    }
}
