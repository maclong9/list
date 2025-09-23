import Foundation

/// Enum defining terminal color codes.
public enum TerminalColors: String {
    case white = "\u{001B}[0;37m"
    case yellow = "\u{001B}[0;33m"
    case red = "\u{001B}[0;31m"
    case blue = "\u{001B}[0;34m"
    case reset = "\u{001B}[0;0m"
}