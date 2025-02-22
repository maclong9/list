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
      #expect(result.contains("sls.swiftmodule"))
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
      #expect(result.contains("arm64-apple-macos.swiftdoc"))
    }
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
      #expect(result.contains("📃"))
    }

    if flag.contains("oneLine") {
      #expect(result.contains("sls\n"))
    }
  }
}
