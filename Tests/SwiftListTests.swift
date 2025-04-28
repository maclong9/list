import Foundation
import RegexBuilder
import Testing

@testable import sls

extension Tag {
  @Tag static var functionality: Tag
  @Tag static var formatting: Tag
}

struct CoreFunctionality {
  @Test(
    "List Files in Directory",
    .tags(.functionality),
    arguments: [
      nil,
      "/Users",
    ]
  )
  func listFiles(path: String?) async throws {
    let location: URL? = path.map { URL(fileURLWithPath: $0) }

    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: location
      )
    )

    if path == nil {
      #expect(result.contains("Package.swift"))
    } else {
      #expect(result.contains("Shared"))
    }
  }

  @Test(
    "Flags Perform Correctly",
    arguments: [
      "all",
      "long",
      "recurse",
      "sort=name",
      "sort=time",
      "sort=size",
    ]
  )
  func coreFlags(flag: String) async throws {
    var location: URL?
    if flag.contains("all") {
      location = FileManagerHelper.fm.temporaryDirectory.appendingPathComponent("temp")
      try FileManagerHelper.fm.createDirectory(
        at: location!,
        withIntermediateDirectories: true,
        attributes: nil
      )

      FileManagerHelper.fm.createFile(
        atPath: location!.appendingPathComponent(".hiddenFile").path,
        contents: Data("hidden".utf8),
        attributes: nil
      )
    }

    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: flag.contains("all") ? location : nil,
        all: flag.contains("all"),
        long: flag.contains("long"),
        recurse: flag.contains("recurse"),
        sortBy: flag.contains("sort=time") ? .time : flag.contains("sort=size") ? .size : .name
      )
    )

    if flag.contains("all") {
      #expect(result.contains(".hiddenFile"))
      try FileManagerHelper.fm.removeItem(at: location!)
    }

    if flag.contains("long") {
      #expect(result.contains("staff"))
    }

    if flag.contains("recurse") {
      #expect(result.contains("SwiftListTests.swift"))
    }
  }

  @Test("List Multiple Paths", .tags(.functionality))
  func listMultiplePaths() async throws {
    let fm = FileManagerHelper.fm
    let tempDir1 = fm.temporaryDirectory.appendingPathComponent("testDir1")
    let tempDir2 = fm.temporaryDirectory.appendingPathComponent("testDir2")

    try fm.createDirectory(at: tempDir1, withIntermediateDirectories: true, attributes: nil)
    try fm.createDirectory(at: tempDir2, withIntermediateDirectories: true, attributes: nil)

    fm.createFile(atPath: tempDir1.appendingPathComponent("file1.txt").path, contents: Data("file1".utf8), attributes: nil)
    fm.createFile(atPath: tempDir2.appendingPathComponent("file2.txt").path, contents: Data("file2".utf8), attributes: nil)

    let arguments = [tempDir1.path, tempDir2.path]
    let command = try sls.parse(arguments)

    let output = try captureOutput {
      try command.run()
    }

    #expect(output.contains("\(tempDir1.path):"))
    #expect(output.contains("file1.txt"))
    #expect(output.contains("\(tempDir2.path):"))
    #expect(output.contains("file2.txt"))
    #expect(output.contains("\n\n"))

    try fm.removeItem(at: tempDir1)
    try fm.removeItem(at: tempDir2)
  }
}

// Helper to capture command output
extension CoreFunctionality {
  func captureOutput(_ closure: () throws -> Void) throws -> String {
    let pipe = Pipe()
    let originalStdout = dup(STDOUT_FILENO)
    defer { close(originalStdout) }

    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    pipe.fileHandleForWriting.closeFile()

    try closure()

    dup2(originalStdout, STDOUT_FILENO)

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
  }
}

struct Formatting {
  @Test(
    "Formatting Flags Perform Properly",
    .tags(.formatting),
    arguments: [
      "color",
      "icons",
      "oneLine",
    ]
  )
  func formattingFlags(flag: String) async throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        color: flag.contains("color"),
        icons: flag.contains("icons"),
        oneLine: flag.contains("oneLine")
      )
    )

    if flag.contains("color") {
      #expect(
        result.contains(
          Regex {
            "[0;"
            OneOrMore(.digit)
            "m"
          }
        )
      )
    }

    if flag.contains("icons") {
      #expect(result.contains("📄"))
    }

    if flag.contains("oneLine") {
      #expect(result.contains("Package.swift\n"))
    }
  }
}
