#!/usr/bin/env swift

// GenerateTopicStrings.swift
//
// Fetches localized article topic strings from the MediaWiki allmessages API
// and injects them into the matching .lproj/Localizable.strings files inside
// the WMFNativeLocalizations Resources directory.
//
// Run from anywhere inside the repo:
//
//   swift GenerateTopicsStrings.swift
//
// Or with options:
//
//   swift GenerateTopicsStrings.swift en es          # specific languages
//   swift GenerateTopicsStrings.swift en --stdout    # preview without writing

import Foundation

// MARK: - Message keys

let msgKeys: [String] = [
    "wikimedia-articletopics-topic-architecture",
    "wikimedia-articletopics-topic-art",
    "wikimedia-articletopics-topic-comics-and-anime",
    "wikimedia-articletopics-topic-entertainment",
    "wikimedia-articletopics-topic-fashion",
    "wikimedia-articletopics-topic-literature",
    "wikimedia-articletopics-topic-music",
    "wikimedia-articletopics-topic-performing-arts",
    "wikimedia-articletopics-topic-sports",
    "wikimedia-articletopics-topic-tv-and-film",
    "wikimedia-articletopics-topic-video-games",
    "wikimedia-articletopics-topic-biography",
    "wikimedia-articletopics-topic-women",
    "wikimedia-articletopics-topic-business-and-economics",
    "wikimedia-articletopics-topic-education",
    "wikimedia-articletopics-topic-food-and-drink",
    "wikimedia-articletopics-topic-history",
    "wikimedia-articletopics-topic-military-and-warfare",
    "wikimedia-articletopics-topic-philosophy-and-religion",
    "wikimedia-articletopics-topic-politics-and-government",
    "wikimedia-articletopics-topic-society",
    "wikimedia-articletopics-topic-transportation",
    "wikimedia-articletopics-topic-biology",
    "wikimedia-articletopics-topic-chemistry",
    "wikimedia-articletopics-topic-computers-and-internet",
    "wikimedia-articletopics-topic-earth-and-environment",
    "wikimedia-articletopics-topic-engineering",
    "wikimedia-articletopics-topic-general-science",
    "wikimedia-articletopics-topic-mathematics",
    "wikimedia-articletopics-topic-medicine-and-health",
    "wikimedia-articletopics-topic-physics",
    "wikimedia-articletopics-topic-technology",
    "wikimedia-articletopics-topic-africa",
    "wikimedia-articletopics-topic-asia",
    "wikimedia-articletopics-topic-central-america",
    "wikimedia-articletopics-topic-europe",
    "wikimedia-articletopics-topic-north-america",
    "wikimedia-articletopics-topic-oceania",
    "wikimedia-articletopics-topic-south-america"
]

// MARK: - Language mapping
//
// Maps MediaWiki language codes to .lproj folder names where the two differ.
// Mirrors the logic in WMFLocalizedString.swift so written keys land in the
// bundle the runtime reads. Falls back to the MediaWiki code itself when no
// entry is present.

let mediawikiToLproj: [String: String] = [
    "gsw":     "als",
    "ku-latn": "ku",
    "pt-br":   "pt-BR",
    "sh-latn":  "sh",
    "sr-ec":   "sr",
    "uz-cyrl": "uz",
    "zh-hk":   "zh-hant",
    "zh-mo":   "zh-hant",
    "zh-my":   "zh-hans",
    "zh-sg":   "zh-hans",
    "zh-tw":   "zh-hant"
]

func lprojFolderName(for languageCode: String) -> String {
    mediawikiToLproj[languageCode] ?? languageCode
}

// MARK: - Paths

// This file sits in Sources/WMFNativeLocalizations/.
// Resources/ is a sibling of this file.
let scriptURL = URL(fileURLWithPath: #filePath)
let resourcesURL = scriptURL
    .deletingLastPathComponent()  // WMFLocalizations/
    .deletingLastPathComponent()  // wikipedia-ios/
    .appendingPathComponent("Wikipedia")
    .appendingPathComponent("Localizations")

let topicsAPIURL = URL(string: "https://en.wikipedia.org/w/api.php")!
let languagesAPIURL = URL(string: "https://www.mediawiki.org/w/api.php")!

// MARK: - Argument parsing

var targetLanguages: [String] = []
var printToStdout = false

var argIndex = 1
while argIndex < CommandLine.arguments.count {
    let arg = CommandLine.arguments[argIndex]
    switch arg {
    case "--stdout":
        printToStdout = true
    case "--help", "-h":
        print("""
        USAGE: swift GenerateTopicStrings.swift [<language> ...] [--stdout]

          <language>   MediaWiki language codes (e.g. en es zh-hans).
                       Omit to update all languages with an existing .lproj folder.
          --stdout     Print entries to stdout instead of writing. Requires one language.
        """)
        exit(0)
    default:
        targetLanguages.append(arg)
    }
    argIndex += 1
}

if printToStdout && targetLanguages.count != 1 {
    fputs("Error: --stdout requires exactly one language code.\n", stderr)
    exit(1)
}

// MARK: - Networking

let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.httpAdditionalHeaders = [
        "User-Agent": "wikipedia-ios-topic-string-generator/1.0 (ios@wikimedia.org)"
    ]
    return URLSession(configuration: config)
}()

func fetchJSON(url: URL, queryItems: [URLQueryItem]) throws -> Any {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.queryItems = queryItems
    guard let requestURL = components?.url else {
        throw ScriptError("Could not build request URL.")
    }

    var result: Result<Data, Error> = .failure(ScriptError("Request never completed."))
    let semaphore = DispatchSemaphore(value: 0)

    session.dataTask(with: requestURL) { data, response, error in
        if let error {
            result = .failure(error)
        } else if let data {
            result = .success(data)
        }
        semaphore.signal()
    }.resume()

    semaphore.wait()

    let data = try result.get()
    return try JSONSerialization.jsonObject(with: data)
}

func fetchAvailableLanguageCodes() throws -> [String] {
    let json = try fetchJSON(url: languagesAPIURL, queryItems: [
        URLQueryItem(name: "action", value: "query"),
        URLQueryItem(name: "format", value: "json"),
        URLQueryItem(name: "meta", value: "siteinfo"),
        URLQueryItem(name: "formatversion", value: "2"),
        URLQueryItem(name: "siprop", value: "languages")
    ])

    guard
        let root = json as? [String: Any],
        let query = root["query"] as? [String: Any],
        let languages = query["languages"] as? [[String: Any]]
    else {
        throw ScriptError("Unexpected siteinfo response shape.")
    }

    return languages.compactMap { $0["code"] as? String }
}

func fetchMessages(languageCode: String) throws -> [String: String] {
    let json = try fetchJSON(url: topicsAPIURL, queryItems: [
        URLQueryItem(name: "format", value: "json"),
        URLQueryItem(name: "formatversion", value: "2"),
        URLQueryItem(name: "errorformat", value: "html"),
        URLQueryItem(name: "errorsuselocal", value: "1"),
        URLQueryItem(name: "action", value: "query"),
        URLQueryItem(name: "meta", value: "allmessages"),
        URLQueryItem(name: "amenableparser", value: "1"),
        URLQueryItem(name: "ammessages", value: msgKeys.joined(separator: "|")),
        URLQueryItem(name: "amlang", value: languageCode)
    ])

    guard
        let root = json as? [String: Any],
        let query = root["query"] as? [String: Any],
        let messages = query["allmessages"] as? [[String: Any]]
    else {
        throw ScriptError("Unexpected allmessages response shape for '\(languageCode)'.")
    }

    var result: [String: String] = [:]
    for message in messages {
        guard
            message["missing"] == nil,
            let name = message["name"] as? String,
            let content = message["content"] as? String,
            !content.isEmpty
        else { continue }
        result[name] = content
    }
    return result
}

// MARK: - Strings file injection

func escapeStringsValue(_ string: String) -> String {
    string
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
}

func buildEntry(key: String, value: String) -> String {
    "/* Article topic label */\n\"\(escapeStringsValue(key))\" = \"\(escapeStringsValue(value))\";"
}

// Parse a .strings file into an ordered list of raw lines, and a separate
// lookup of key -> line index for any key that appears in msgKeys.
//
// Strategy: scan line by line looking for lines of the form:
//   "some-key" = "some value";
// When a key matches one of our managed keys, record which line it's on
// (including the optional comment line immediately above it) so we can
// replace just that entry in place. Everything else is left untouched.

func injectIntoStringsFile(at url: URL, translations: [String: String]) throws {
    var encoding: String.Encoding = .utf8
    let existing: String
    if url.isFileURL, FileManager.default.fileExists(atPath: url.path) {
        existing = (try? String(contentsOf: url, usedEncoding: &encoding)) ?? ""
    } else {
        existing = ""
    }
    var lines = existing.components(separatedBy: "\n")

    // Simple key extraction: if a line looks like `"key" = ...;` return the key.
    // We only need to match lines whose key is in our managed set, so we can
    // use a straightforward prefix/suffix check rather than a full parser.
    func managedKey(from line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("\"") else { return nil }
        // Find the closing quote of the key portion.
        var i = trimmed.index(after: trimmed.startIndex)
        while i < trimmed.endIndex {
            let ch = trimmed[i]
            if ch == "\\" {
                // skip escaped character
                let next = trimmed.index(after: i)
                if next < trimmed.endIndex {
                    i = trimmed.index(after: next)
                } else {
                    break
                }
            } else if ch == "\"" {
                break
            } else {
                i = trimmed.index(after: i)
            }
        }
        guard i < trimmed.endIndex else { return nil }
        let key = String(trimmed[trimmed.index(after: trimmed.startIndex)..<i])
        guard translations[key] != nil else { return nil }
        return key
    }

    var replaced = Set<String>()

    // Walk lines. When we find a managed key, replace the value on that line.
    // The comment line above it (if any) stays untouched — we only rewrite
    // the key = value line itself.
    for idx in lines.indices {
        guard let key = managedKey(from: lines[idx]) else { continue }
        guard let value = translations[key] else { continue }
        replaced.insert(key)
        lines[idx] = "\"\(escapeStringsValue(key))\" = \"\(escapeStringsValue(value))\";"
    }

    // Append entries for any managed keys not already present in the file.
    let newEntries = msgKeys
        .filter { translations[$0] != nil && !replaced.contains($0) }
        .map { buildEntry(key: $0, value: translations[$0]!) }

    var result = lines.joined(separator: "\n")

    if !newEntries.isEmpty {
        let trimmed = result.trimmingCharacters(in: .newlines)
        let separator = trimmed.isEmpty ? "" : "\n\n"
        result = trimmed + separator + "\n" + newEntries.joined(separator: "\n\n") + "\n"
    }

    try result.write(to: url, atomically: true, encoding: encoding)
}

// MARK: - Resolve target languages

func existingLprojNames() -> Set<String> {
    let contents = (try? FileManager.default.contentsOfDirectory(
        at: resourcesURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: .skipsHiddenFiles
    )) ?? []
    return Set(contents.filter { $0.pathExtension == "lproj" }.map { $0.deletingPathExtension().lastPathComponent })
}

func resolveTargetLanguages() throws -> [String] {
    guard !targetLanguages.isEmpty else {
        let existing = existingLprojNames()
        let available = try fetchAvailableLanguageCodes()
        return available.filter { existing.contains(lprojFolderName(for: $0)) }
    }
    return targetLanguages
}

// MARK: - Error

struct ScriptError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { self.errorDescription = message }
}

// MARK: - Main

do {
    let languages = try resolveTargetLanguages()

    if languages.isEmpty {
        fputs("No matching .lproj folders found.\n", stderr)
        exit(1)
    }

    for (offset, languageCode) in languages.enumerated() {
        do {
            let translations = try fetchMessages(languageCode: languageCode)

            guard !translations.isEmpty else {
                print("Skipping '\(languageCode)': no translations available.")
                continue
            }

            if printToStdout {
                for key in msgKeys {
                    if let value = translations[key] {
                        print(buildEntry(key: key, value: value))
                    }
                }
                break
            }

            let folder = lprojFolderName(for: languageCode)
            let lprojURL = resourcesURL.appendingPathComponent("\(folder).lproj")
            let stringsURL = lprojURL.appendingPathComponent("Localizable.strings")

            try FileManager.default.createDirectory(at: lprojURL, withIntermediateDirectories: true)
            try injectIntoStringsFile(at: stringsURL, translations: translations)

            print("Updated \(stringsURL.path) (\(translations.count)/\(msgKeys.count) keys)")

            if offset < languages.count - 1 {
                Thread.sleep(forTimeInterval: 0.5)
            }
        } catch {
            fputs("Skipping '\(languageCode)': \(error.localizedDescription)\n", stderr)
        }
    }
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
