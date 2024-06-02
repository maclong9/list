import ArgumentParser
import Foundation

let files = FileManager.default

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
  @Argument(help: "List files at path, omit for current directory.")
  var path: String?

  func run() throws {
    let files = FileManager.default
    let location = URL(fileURLWithPath: path ?? files.currentDirectoryPath)
    do {
      let contents = try files.contentsOfDirectory(
        at: location,
        includingPropertiesForKeys: nil,
        options: all ? [] : [.skipsHiddenFiles]
      )
      
      for url in contents {
        print(url.lastPathComponent)
      }
    } catch {
      print("Failed to list contents of directory: \(error)")
    }
  }
}
