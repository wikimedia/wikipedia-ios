#!/usr/bin/env swift
// Drives the VisualEditor oracle harness (harness/harness.html) in an offscreen
// WKWebView and round-trips every document in corpus/ through VE's document model.
//
// Usage: swift run_oracle.swift [--dump-linear]
//
// Writes results/summary.json plus, per document, the round-tripped body HTML
// (and optionally the linear model dump) for inspection and for use as
// differential-test fixtures by the Swift engine.

import AppKit
import WebKit

let oracleDirectory = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let harnessURL = oracleDirectory.appendingPathComponent("harness/harness.html")
let corpusDirectory = oracleDirectory.appendingPathComponent("corpus")
let resultsDirectory = oracleDirectory.appendingPathComponent("results")
let dumpLinearData = CommandLine.arguments.contains("--dump-linear")

// WKWebView requires a run loop; pumping it manually keeps the script linear.
func pump(until predicate: () -> Bool, timeout: TimeInterval) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while !predicate() && Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    return predicate()
}

final class NavigationObserver: NSObject, WKNavigationDelegate {
    var finished = false
    var failed: String?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        finished = true
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        failed = error.localizedDescription
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        failed = error.localizedDescription
    }
}

func evaluate(_ webView: WKWebView, _ script: String, arguments: [String: Any] = [:]) -> Result<Any?, Error> {
    var result: Result<Any?, Error>?
    webView.callAsyncJavaScript(script, arguments: arguments, in: nil, in: .page) { outcome in
        result = outcome.map { $0 as Any? }
    }
    _ = pump(until: { result != nil }, timeout: 300)
    return result ?? .failure(NSError(domain: "oracle", code: 1, userInfo: [NSLocalizedDescriptionKey: "timed out"]))
}

_ = NSApplication.shared

let observer = NavigationObserver()
let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1024, height: 768))
webView.navigationDelegate = observer
webView.loadFileURL(harnessURL, allowingReadAccessTo: oracleDirectory)

guard pump(until: { observer.finished || observer.failed != nil }, timeout: 60), observer.failed == nil else {
    print("FATAL: harness failed to load: \(observer.failed ?? "timeout")")
    exit(1)
}

// Surface any script-loading errors captured by window.onerror before proceeding.
if case .success(let loadErrors?) = evaluate(webView, "return window.wmfLoadErrors"),
   let errors = loadErrors as? [String], !errors.isEmpty {
    print("FATAL: harness script errors:")
    errors.forEach { print("  \($0)") }
    exit(1)
}

guard case .success(let versionInfo?) = evaluate(webView, "return window.wmfOracle.version()") else {
    print("FATAL: wmfOracle API is not available")
    exit(1)
}
print("oracle ready: \(versionInfo)")

let corpusFiles = (try? FileManager.default.contentsOfDirectory(at: corpusDirectory, includingPropertiesForKeys: nil))?
    .filter { $0.pathExtension == "html" }
    .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []

guard !corpusFiles.isEmpty else {
    print("FATAL: empty corpus — run fetch_corpus.py first")
    exit(1)
}

try? FileManager.default.createDirectory(at: resultsDirectory, withIntermediateDirectories: true)

var summary: [[String: Any]] = []
var idempotentCount = 0
var identicalToInputCount = 0
var failureCount = 0

for fileURL in corpusFiles {
    let name = fileURL.lastPathComponent
    guard let html = try? String(contentsOf: fileURL, encoding: .utf8) else {
        print("SKIP \(name): unreadable")
        continue
    }

    let started = Date()
    let outcome = evaluate(
        webView,
        "return window.wmfOracle.process(html, includeLinearData)",
        arguments: ["html": html, "includeLinearData": dumpLinearData]
    )
    let elapsed = Date().timeIntervalSince(started)

    guard case .success(let value?) = outcome, let dictionary = value as? [String: Any] else {
        print("FAIL \(name): bridge error \(outcome)")
        failureCount += 1
        summary.append(["file": name, "ok": false, "error": "bridge failure"])
        continue
    }

    if dictionary["ok"] as? Bool != true {
        let message = dictionary["error"] as? String ?? "unknown"
        print("FAIL \(name): \(message)")
        failureCount += 1
        summary.append(["file": name, "ok": false, "error": message])
        continue
    }

    let idempotent = dictionary["idempotent"] as? Bool ?? false
    let inputMatchesOutput = dictionary["inputMatchesOutput"] as? Bool ?? false
    let linearLength = dictionary["linearLength"] as? Int ?? 0
    if idempotent { idempotentCount += 1 }
    if inputMatchesOutput { identicalToInputCount += 1 }

    if let firstHTML = dictionary["firstHTML"] as? String {
        try? firstHTML.write(to: resultsDirectory.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
    if dumpLinearData, let linearData = dictionary["linearData"],
       let jsonData = try? JSONSerialization.data(withJSONObject: linearData) {
        try? jsonData.write(to: resultsDirectory.appendingPathComponent(name + ".linear.json"))
    }

    summary.append([
        "file": name,
        "ok": true,
        "idempotent": idempotent,
        "inputMatchesOutput": inputMatchesOutput,
        "linearLength": linearLength,
        "nodeTypeCounts": dictionary["nodeTypeCounts"] ?? [:],
        "seconds": (elapsed * 100).rounded() / 100
    ])
    print("OK   \(name): idempotent=\(idempotent) inputMatchesOutput=\(inputMatchesOutput) linear=\(linearLength) (\(String(format: "%.1f", elapsed))s)")
}

let report: [String: Any] = [
    "documents": summary,
    "totals": [
        "processed": summary.count,
        "failures": failureCount,
        "idempotent": idempotentCount,
        "identicalToInput": identicalToInputCount
    ]
]
let reportData = try JSONSerialization.data(withJSONObject: report, options: [.prettyPrinted, .sortedKeys])
try reportData.write(to: resultsDirectory.appendingPathComponent("summary.json"))

print("\n\(summary.count) processed, \(failureCount) failures, \(idempotentCount) idempotent, \(identicalToInputCount) byte-identical to input")
exit(failureCount == 0 ? 0 : 1)
