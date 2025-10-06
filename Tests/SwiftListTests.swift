import Foundation
import RegexBuilder
import Testing

@testable import sls

// Make sure you set custom working directory to project directory

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
            location = FileManagerHelper.fileManager.temporaryDirectory
                .appendingPathComponent("temp")
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
                sortBy: flag.contains("sort=time")
                    ? .time : flag.contains("sort=size") ? .size : .name
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

        try fm.createDirectory(
            at: tempDir1,
            withIntermediateDirectories: true,
            attributes: nil
        )
        try fm.createDirectory(
            at: tempDir2,
            withIntermediateDirectories: true,
            attributes: nil
        )

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
        let command = try List.parse(arguments)

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
            #expect(result.contains("Package.swift"))
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
    // Helper to get the built binary path
    private func getExecutablePath() -> String? {
        let fm = FileManager.default
        let currentDir = fm.currentDirectoryPath

        // Try to find the built executable
        let possiblePaths = [
            "\(currentDir)/.build/arm64-apple-macosx/debug/sls",
            "\(currentDir)/.build/x86_64-apple-macosx/debug/sls",
            "\(currentDir)/.build/debug/sls",
        ]

        for path in possiblePaths {
            if fm.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    // Helper to run completion command
    private func runCompletionCommand(shell: String) throws -> (output: String, exitCode: Int32) {
        guard let execPath = getExecutablePath() else {
            throw NSError(
                domain: "TestError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Could not find sls executable. Run 'swift build' first."]
            )
        }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: execPath)
        process.arguments = ["--generate-completion-script", shell]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        try process.run()

        // Close write ends to prevent hanging
        try? outputPipe.fileHandleForWriting.close()
        try? errorPipe.fileHandleForWriting.close()

        process.waitUntilExit()

        let data = try outputPipe.fileHandleForReading.readToEnd() ?? Data()
        let output = String(data: data, encoding: .utf8) ?? ""

        return (output, process.terminationStatus)
    }

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
        let result = try runCompletionCommand(shell: shell)
        let output = result.output

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
        let result = try runCompletionCommand(shell: shell)
        let output = result.output

        // Check for key flags and options
        let expectedOptions = [
            "all", "long", "recurse", "color", "icons",
            "one-line", "human-readable", "sort-time",
            "sort-size", "directory", "classify", "help",
        ]

        for option in expectedOptions {
            #expect(
                output.contains(option),
                "Missing option: \(option) in \(shell) completion"
            )
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
        let result = try runCompletionCommand(shell: shell)
        let output = result.output

        // Check for key short flags
        let expectedShortFlags = [
            "a", "l", "r", "c", "i", "o", "t", "S", "d", "F", "h",
        ]

        for flag in expectedShortFlags {
            if shell == "fish" {
                #expect(
                    output.contains("-s \(flag)"),
                    "Missing short flag: \(flag) in \(shell) completion"
                )
            } else {
                #expect(
                    output.contains("-\(flag)"),
                    "Missing short flag: \(flag) in \(shell) completion"
                )
            }
        }
    }

    @Test(
        "Invalid shell produces error",
        .tags(.completion)
    )
    func invalidShellProducesError() async throws {
        let result = try runCompletionCommand(shell: "invalid-shell")

        #expect(
            result.exitCode != 0,
            "Invalid shell should produce non-zero exit code"
        )
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
        let result = try runCompletionCommand(shell: shell)
        let output = result.output

        // Basic syntax validation
        switch shell {
            case "bash":
                // Check for balanced braces and parentheses
                let openBraces = output.components(separatedBy: "{").count - 1
                let closeBraces = output.components(separatedBy: "}").count - 1
                #expect(
                    openBraces == closeBraces,
                    "Unbalanced braces in bash completion"
                )

                let openParens = output.components(separatedBy: "(").count - 1
                let closeParens = output.components(separatedBy: ")").count - 1
                #expect(
                    openParens == closeParens,
                    "Unbalanced parentheses in bash completion"
                )

            case "zsh":
                // Check for balanced parentheses and proper zsh syntax
                let openParens = output.components(separatedBy: "(").count - 1
                let closeParens = output.components(separatedBy: ")").count - 1
                #expect(
                    openParens == closeParens,
                    "Unbalanced parentheses in zsh completion"
                )

            case "fish":
                // Check for proper fish function syntax
                let functionCount =
                    output.components(separatedBy: "function ").count - 1
                let endCount = output.components(separatedBy: "end").count - 1
                #expect(
                    functionCount <= endCount,
                    "Invalid fish function structure"
                )

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
