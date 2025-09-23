import Foundation

/// Stores display options for listing files.
public struct DisplayOptions {
    /// The location to list files from
    public var location: URL?
    
    /// Whether to show hidden files
    public var all = false
    
    /// Whether to use long listing format
    public var long = false
    
    /// Whether to recurse into subdirectories
    public var recurse = false
    
    /// Whether to colorize the output
    public var color = false
    
    /// Whether to show file type icons
    public var icons = false
    
    /// Whether to display one file per line
    public var oneLine = false
    
    /// Whether to show human-readable file sizes
    public var humanReadable = false
    
    /// Whether to list directories themselves, not their contents
    public var directoryOnly = false
    
    /// Whether to append indicators (/, *, etc.) to entries
    public var classify = false
    
    /// How to sort the file listing
    public var sortBy: SortOption = .name
    
    /// Creates a new DisplayOptions instance with the specified options
    /// - Parameters:
    ///   - location: The location to list files from (optional)
    ///   - all: Whether to show hidden files
    ///   - long: Whether to use long listing format
    ///   - recurse: Whether to recurse into subdirectories
    ///   - color: Whether to colorize the output
    ///   - icons: Whether to show file type icons
    ///   - oneLine: Whether to display one file per line
    ///   - humanReadable: Whether to show human-readable file sizes
    ///   - directoryOnly: Whether to list directories themselves
    ///   - classify: Whether to append indicators to entries
    ///   - sortBy: How to sort the file listing
    public init(
        location: URL? = nil,
        all: Bool = false,
        long: Bool = false,
        recurse: Bool = false,
        color: Bool = false,
        icons: Bool = false,
        oneLine: Bool = false,
        humanReadable: Bool = false,
        directoryOnly: Bool = false,
        classify: Bool = false,
        sortBy: SortOption = .name
    ) {
        self.location = location
        self.all = all
        self.long = long
        self.recurse = recurse
        self.color = color
        self.icons = icons
        self.oneLine = oneLine
        self.humanReadable = humanReadable
        self.directoryOnly = directoryOnly
        self.classify = classify
        self.sortBy = sortBy
    }
}