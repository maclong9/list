import ArgumentParser
import XCTest

@testable import sls

final class SwiftListTests: XCTestCase {
  var tempDir: URL!

  // Creates tempDir with some example files
  override func setUpWithError() throws {
    tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(
      UUID().uuidString
    )
    let testDir = tempDir.appendingPathComponent("testDir")

    try FileManagerHelper.fm.createDirectory(
      at: testDir,
      withIntermediateDirectories: true
    )

    FileManagerHelper.fm.createFile(
      atPath: tempDir.appendingPathComponent("testFile1.txt").path,
      contents: "Test file 1 content".data(using: .utf8)
    )

    FileManagerHelper.fm.createFile(
      atPath: tempDir.appendingPathComponent(".hiddenFile").path,
      contents: "Hidden file content".data(using: .utf8)
    )

    let executableFile = tempDir.appendingPathComponent("executableFile.sh")
    FileManagerHelper.fm.createFile(
      atPath: executableFile.path,
      contents: "#!/bin/sh\necho Hello, World!".data(using: .utf8)
    )
    var attributes = [FileAttributeKey: Any]()
    attributes[.posixPermissions] = 0o755  // rwxr-xr-x
    try FileManager.default.setAttributes(
      attributes, ofItemAtPath: executableFile.path
    )

    FileManagerHelper.fm.createFile(
      atPath: testDir.appendingPathComponent("hello.swift").path,
      contents:
        "import Foundation\n let name = \"Mac\"\n for _ in 1...5 {\n print(\"Hello, \\(name)\")\n sleep(1)\n }"
        .data(using: .utf8)
    )
  }

  // Removes tempDir
  override func tearDownWithError() throws {
    try FileManagerHelper.fm.removeItem(at: tempDir)
  }

  // Lists files in current directory
  func testListFiles() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: nil,
        all: false,
        long: false,
        recurse: false,
        color: false,
        icons: false,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains("sls.swiftmodule"))
    XCTAssertTrue(result.contains("sls"))
    XCTAssertTrue(result.contains("PackageFrameworks"))
  }

  // Lists files at specified directory
  func testListFilesAtDirectory() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: false,
        recurse: false,
        color: false,
        icons: false,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains("testFile1.txt"))
    XCTAssertFalse(result.contains(".hiddenFile"))
    XCTAssertTrue(result.contains("testDir"))
    XCTAssertTrue(result.contains("executableFile.sh"))
  }

  // Attempts to list files at a non-existent URL
  func testListWithNonExistentDirectory() throws {
    do {
      _ = try FileManagerHelper.findContents(
        with: DisplayOptions(
          location: URL(fileURLWithPath: "/Users/noone/non-existent"),
          all: false,
          long: false,
          recurse: false,
          color: false,
          icons: false,
          oneLine: false
        )
      )

      XCTFail("Expected an error to be thrown for non-existent directory")
    } catch let error as NSError {
      XCTAssertTrue(
        error.domain == NSCocoaErrorDomain && error.code == NSFileReadNoSuchFileError,
        "Expected NSFileReadNoSuchFileError for non-existent directory"
      )
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  // Lists files at specified directory with --all flag
  func testListAllFiles() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: true,
        long: false,
        recurse: false,
        color: false,
        icons: false,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains(".hiddenFile"))
  }

  // Lists files at specified directory with --long flag
  func testListFilesWithLong() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: true,
        recurse: false,
        color: false,
        icons: false,
        oneLine: false
      )
    )

    let regexPattern =
      #"493\s+\w+\s+\w+\s+1\s+28\s+\d{2}\s+Jun\s+\d{2}:\d{2}\s+executableFile\.sh\n"#
    let regex = try! NSRegularExpression(pattern: regexPattern)
    let range = NSRange(location: 0, length: result.utf16.count)
    print(result)
    XCTAssertNotNil(
      regex.firstMatch(
        in: result,
        options: [],
        range: range
      ),
      "Output does not match expected format."
    )
  }

  // Lists files at specified directory with --recurse flag
  func testListWithRecurse() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: false,
        recurse: true,
        color: false,
        icons: false,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains("./testDir:"))
    XCTAssertTrue(result.contains("hello.swift"))
  }

  // Lists files at specified directory with --color flag
  func testListWithColor() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: false,
        recurse: true,
        color: true,
        icons: false,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains("[0;37m"))
    XCTAssertTrue(result.contains("[0;31m"))
    XCTAssertTrue(result.contains("[0;34m"))
  }

  // Lists files at specified directory with --icons flag
  func testListWithIcons() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: false,
        recurse: false,
        color: false,
        icons: true,
        oneLine: false
      )
    )

    XCTAssertTrue(result.contains("📃"))
    XCTAssertTrue(result.contains("📁"))
    XCTAssertTrue(result.contains("⚙️"))
  }

  // Lists files at specified directory with --oneLine flag
  func testListWithOneLine() throws {
    let result = try FileManagerHelper.findContents(
      with: DisplayOptions(
        location: tempDir,
        all: false,
        long: false,
        recurse: false,
        color: false,
        icons: false,
        oneLine: true
      )
    )

    XCTAssertTrue(result.contains("executableFile.sh\n"))
    XCTAssertTrue(result.contains("testDir\n"))
    XCTAssertTrue(result.contains("testFile1.txt\n"))
  }

  func testFindContentsPerformance() throws {
    measure {
      do {
        _ = try FileManagerHelper.findContents(
          with: DisplayOptions(
            location: tempDir,
            all: false,
            long: false,
            recurse: true,
            color: false,
            icons: false,
            oneLine: false
          )
        )
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }
}
