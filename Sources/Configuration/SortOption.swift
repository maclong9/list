import ArgumentParser
import Foundation

/// Enum defining sorting options.
public enum SortOption: String, ExpressibleByArgument {
    /// Sort by name (default)
    case name
    /// Sort by modification time
    case time
    /// Sort by file size
    case size
}
