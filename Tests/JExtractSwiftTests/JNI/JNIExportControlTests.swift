//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2026 Apple Inc. and the Swift.org project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of Swift.org project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CodePrinting
import JExtractSwiftLib
import SwiftExtract
import SwiftJavaConfigurationShared
import Testing

/// `@JavaExport(false)` opts declarations out, and `exportMode: annotated` exports only marked ones.
@Suite
struct JNIExportControlTests {
  let optOutSource =
    """
    public struct Session {
      public var token: String
      @JavaExport(false) public var secret: String
      @JavaExport(false) public func pairs() -> [(Int64, String)] { [] }
    }
    @JavaExport(false)
    public struct Hidden {
      public func pairs() -> [(Int64, String)] { [] }
    }
    @JavaExport(false)
    extension Session {
      public func fromExtension() -> [(Int64, String)] { [] }
    }
    public struct Interval {
      public var seconds: Int64
      public prefix static func - (lhs: Interval) -> Interval { lhs }
    }
    @JavaExport(false)
    extension UnknownType {
      public func helper() {}
    }
    """

  let annotatedSource =
    """
    @JavaExport
    public struct Exported {
      public var name: String
      @JavaExport(false) public var hidden: String
    }
    public struct Partial {
      @JavaExport public func picked() {}
      public func notPicked() {}
    }
    public struct Unmarked {
      public func pairs() -> [(Int64, String)] { [] }
    }
    @JavaExport public func topLevel() {}
    public func notExported() {}
    extension UnknownType {
      public func helper() {}
    }
    """

  private func config(_ exportMode: JExtractExportMode) -> Configuration {
    var config = Configuration()
    config.swiftModule = "SwiftModule"
    config.exportMode = exportMode
    return config
  }

  /// Generates Java and Swift, returning every declaration that was skipped along the way.
  private func skipped(_ source: String, _ exportMode: JExtractExportMode) throws -> [String] {
    let config = config(exportMode)
    let sink = SkippedDeclarationCollector()
    let translator = makeSwiftJavaAnalyzer(config: config, diagnosticsSink: sink)
    try translator.analyze(path: "/fake/Fake.swiftinterface", text: source)
    let generator = JNISwift2JavaGenerator(
      config: config,
      translator: translator,
      javaPackage: "com.example.swift",
      swiftOutputDirectory: "/fake",
      javaOutputDirectory: "/fake",
      javaClassLookupTable: [:],
      moduleJavaPackages: [:]
    )
    var javaPrinter = JavaPrinter(mode: .accumulateAll)
    try generator.writeExportedJavaSources(&javaPrinter)
    var swiftPrinter = SwiftPrinter(mode: .accumulateAll)
    try generator.writeSwiftThunkSources(&swiftPrinter)
    return sink.skipped + generator.skippedDeclarations
  }

  @Test
  func optedOutDeclarationsAreNotExported() throws {
    try assertOutput(
      input: optOutSource,
      config: config(.all),
      .jni,
      .java,
      expectedChunks: [
        "public java.lang.String getToken()",
        "public long getSeconds()",
      ],
      notExpectedChunks: [
        "getSecret",
        "pairs",
        "Hidden",
        "fromExtension",
      ]
    )
  }

  @Test
  func optedOutAndOperatorDeclarationsAreNotSkipped() throws {
    let skipped = try skipped(optOutSource, .all)
    #expect(skipped.isEmpty, "\(skipped)")
  }

  @Test
  func annotatedModeExportsOnlyMarkedDeclarations() throws {
    try assertOutput(
      input: annotatedSource,
      config: config(.annotated),
      .jni,
      .java,
      expectedChunks: [
        "public java.lang.String getName()",
        "public void picked()",
        "public static void topLevel()",
      ],
      notExpectedChunks: [
        "getHidden",
        "notPicked",
        "Unmarked",
        "notExported",
      ]
    )
  }

  @Test
  func annotatedModeDoesNotSkipUnmarkedDeclarations() throws {
    let skipped = try skipped(annotatedSource, .annotated)
    #expect(skipped.isEmpty, "\(skipped)")
  }
}
