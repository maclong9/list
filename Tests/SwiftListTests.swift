import Foundation
import RegexBuilder
import Testing

@testable import sls

extension Tag {
  @Tag static var functionality: Tag
  @Tag static var formatting: Tag
  @Tag static var completion: Tag
}

@Suite("SLS Core Tests") struct SLSCoreTests {
  @Test(
    "Lists files in directory",
    .tags(.functionality),
    arguments: [
      nil,
      "/Users",
    ]
  )
  func listFilesInDirectory(path: String?) async throws {
    let location: URL? = path.map { URL(fileURLWithPath: $0) }

    let result = try FileManagerHelper.contents(
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
    "Core flags perform correctly",
    .tags(.functionality),
    arguments: [
      "all",
      "long",
      "recurse",
      "sort=name",
      "sort=time",
      "sort=size",
    ]
  )
  func coreFlagsPerformCorrectly(flag: String) async throws {
    var location: URL?
    if flag.contains("all") {
      location = FileManagerHelper.fileManager.temporaryDirectory.appendingPathComponent("temp")
      try FileManagerHelper.fileManager.createDirectory(
        at: location!,
        withIntermediateDirectories: true,
        attributes: [:]
      )

      FileManagerHelper.fileManager.createFile(
        atPath: location!.appendingPathComponent(".hiddenFile").path,
        contents: Data("hidden".utf8),
        attributes: [:]
      )
    }

    let result = try FileManagerHelper.contents(
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
      try FileManagerHelper.fileManager.removeItem(at: location!)
    }

    if flag.contains("long") {
      #expect(result.contains("staff"))
    }

    if flag.contains("recurse") {
      #expect(result.contains("SwiftListTests.swift"))
    }
  }

  @Test(
    "Lists multiple paths",
    .tags(.functionality)
  )
  func listMultiplePaths() async throws {
    let fm = FileManagerHelper.fileManager
    let tempDir1 = fm.temporaryDirectory.appendingPathComponent("testDir1")
    let tempDir2 = fm.temporaryDirectory.appendingPathComponent("testDir2")

    try fm.createDirectory(at: tempDir1, withIntermediateDirectories: true, attributes: nil)
    try fm.createDirectory(at: tempDir2, withIntermediateDirectories: true, attributes: nil)

    fm.createFile(
      atPath: tempDir1.appendingPathComponent("file1.txt").path,
      contents: Data("file1".utf8),
      attributes: nil
    )
    fm.createFile(
      atPath: tempDir2.appendingPathComponent("file2.txt").path,
      contents: Data("file2".utf8),
      attributes: nil
    )

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

  @Test(
    "Formatting flags perform correctly",
    .tags(.formatting),
    arguments: [
      "color",
      "icons",
      "oneLine",
    ]
  )
  func formattingFlagsPerformCorrectly(flag: String) async throws {
    let result = try FileManagerHelper.contents(
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

  // Helper to capture command output
  private func captureOutput(_ closure: () throws -> Void) throws -> String {
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

@Suite("Shell Completion Tests") struct ShellCompletionTests {
  @Test(
    "Generates completion script for supported shells",
    .tags(.completion),
    arguments: [
      "bash",
      "zsh",
      "fish",
    ]
  )
  func generatesCompletionScript(for shell: String) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "run", "sls", "--generate-completion-script", shell]
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    #expect(!output.isEmpty)

    // Verify shell-specific syntax patterns
    switch shell {
    case "bash":
      #expect(output.contains("#!/bin/bash"))
      #expect(output.contains("_sls()"))
      #expect(output.contains("complete -F _sls sls"))
      #expect(output.contains("COMPREPLY"))
    case "zsh":
      #expect(output.contains("#compdef sls"))
      #expect(output.contains("_sls()"))
      #expect(output.contains("_arguments"))
    case "fish":
      #expect(output.contains("function _swift_sls"))
      #expect(output.contains("complete -c sls"))
    default:
      #expect(Bool(false), "Unsupported shell: \(shell)")
    }
  }

  @Test(
    "Completion script includes all command options",
    .tags(.completion),
    arguments: [
      "bash",
      "zsh",
      "fish",
    ]
  )
  func completionScriptIncludesAllOptions(for shell: String) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "run", "sls", "--generate-completion-script", shell]
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    // Check for key flags and options
    let expectedOptions = [
      "all", "long", "recurse", "color", "icons",
      "one-line", "human-readable", "sort-time",
      "sort-size", "directory", "classify", "help",
    ]

    for option in expectedOptions {
      #expect(output.contains(option), "Missing option: \(option) in \(shell) completion")
    }
  }

  @Test(
    "Completion script includes short flags",
    .tags(.completion),
    arguments: [
      "bash",
      "zsh",
      "fish",
    ]
  )
  func completionScriptIncludesShortFlags(for shell: String) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "run", "sls", "--generate-completion-script", shell]
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    // Check for key short flags
    let expectedShortFlags = [
      "-a", "-l", "-r", "-c", "-i", "-o", "-t", "-S", "-d", "-F", "-1", "-h",
    ]

    for flag in expectedShortFlags {
      #expect(output.contains(flag), "Missing short flag: \(flag) in \(shell) completion")
    }
  }

  @Test(
    "Invalid shell produces error",
    .tags(.completion)
  )
  func invalidShellProducesError() async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "run", "sls", "--generate-completion-script", "invalid-shell"]
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    #expect(process.terminationStatus != 0, "Invalid shell should produce non-zero exit code")
  }

  @Test(
    "Completion script syntax is valid",
    .tags(.completion),
    arguments: [
      "bash",
      "zsh",
      "fish",
    ]
  )
  func completionScriptSyntaxIsValid(for shell: String) async throws {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["swift", "run", "sls", "--generate-completion-script", shell]
    process.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = Pipe()

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8) ?? ""

    // Basic syntax validation
    switch shell {
    case "bash":
      // Check for balanced braces and parentheses
      let openBraces = output.components(separatedBy: "{").count - 1
      let closeBraces = output.components(separatedBy: "}").count - 1
      #expect(openBraces == closeBraces, "Unbalanced braces in bash completion")

      let openParens = output.components(separatedBy: "(").count - 1
      let closeParens = output.components(separatedBy: ")").count - 1
      #expect(openParens == closeParens, "Unbalanced parentheses in bash completion")

    case "zsh":
      // Check for balanced parentheses and proper zsh syntax
      let openParens = output.components(separatedBy: "(").count - 1
      let closeParens = output.components(separatedBy: ")").count - 1
      #expect(openParens == closeParens, "Unbalanced parentheses in zsh completion")

    case "fish":
      // Check for proper fish function syntax
      let functionCount = output.components(separatedBy: "function ").count - 1
      let endCount = output.components(separatedBy: "end").count - 1
      #expect(functionCount <= endCount, "Invalid fish function structure")

    default:
      break
    }
  }

  // Helper to capture command output
  private func captureOutput(_ closure: () throws -> Void) throws -> String {
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
