#!/usr/bin/env swift

// GenerateTopicsStrings.swift
//
// Lives in scripts/, outside the Xcode project on purpose: it is run directly
// with the Swift interpreter and must never be compiled into a target (it is
// all top-level code, which is only allowed in a target's main file).
//
// Fetches localized article topic strings from the MediaWiki allmessages API
// and injects them into the matching .lproj/Localizable.strings files inside
// Wikipedia/Localizations. Folder names in that directory are MediaWiki
// language codes, so no code mapping is applied here.
//
// By default, only languages that already have an app bundle at
// WMFLocalizations/Sources/WMFNativeLocalizations/Resources/<code>.lproj/Localizable.strings
// are updated. This keeps the import script (Command Line Tools/Update
// Localizations/localization.swift) from creating brand-new bundles that would
// be mostly copied English text.
//
// Run from the repo root:
//
//   swift scripts/GenerateTopicsStrings.swift
//
// Or with options:
//
//   swift scripts/GenerateTopicsStrings.swift en es          # specific languages (skips the bundle filter)
//   swift scripts/GenerateTopicsStrings.swift en --stdout    # preview without writing

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

// MARK: - Errors

struct ScriptError: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { self.errorDescription = message }
}

// MARK: - Paths

func requiredURL(_ string: String) -> URL {
    guard let url = URL(string: string) else {
        fputs("Invalid URL: \(string)\n", stderr)
        exit(1)
    }
    return url
}

// This file sits in scripts/, one folder below the repo root:
// removing the filename and then the folder lands on the root.
let scriptURL = URL(fileURLWithPath: #filePath)
let repoRootURL = scriptURL
    .deletingLastPathComponent()  // scripts/
    .deletingLastPathComponent()  // repo root

// Where this script writes: TranslateWiki-format strings files, one folder
// per MediaWiki language code.
let localizationsURL = repoRootURL
    .appendingPathComponent("Wikipedia")
    .appendingPathComponent("Localizations")

// Where the import script writes app bundles. Used only to decide which
// languages are worth updating.
let resourcesURL = repoRootURL
    .appendingPathComponent("WMFLocalizations")
    .appendingPathComponent("Sources")
    .appendingPathComponent("WMFNativeLocalizations")
    .appendingPathComponent("Resources")

let topicsAPIURL = requiredURL("https://en.wikipedia.org/w/api.php")
let languagesAPIURL = requiredURL("https://www.mediawiki.org/w/api.php")

// Mirrors twnLocaleToAppStoreConnectLocale in
// Command Line Tools/Update Localizations/localization.swift, so the app
// bundle check below looks in the same folder the import script writes to.
let twnLocaleToAppStoreConnectLocale: [String: String] = [
    "sr-el": "sr-Latn"
]

// MARK: - Argument parsing

struct Options {
    let languages: [String]
    let printToStdout: Bool
}

func parseOptions() -> Options {
    var languages: [String] = []
    var printToStdout = false

    for arg in CommandLine.arguments.dropFirst() {
        switch arg {
        case "--stdout":
            printToStdout = true
        case "--help", "-h":
            print("""
            USAGE: swift GenerateTopicStrings.swift [<language> ...] [--stdout]

              <language>   MediaWiki language codes (e.g. en es zh-hans).
                           Omit to update all languages that have a folder in
                           Wikipedia/Localizations and an existing app bundle
                           in the WMFNativeLocalizations Resources directory.
              --stdout     Print entries to stdout instead of writing. Requires one language.
            """)
            exit(0)
        default:
            languages.append(arg)
        }
    }

    if printToStdout && languages.count != 1 {
        fputs("Error: --stdout requires exactly one language code.\n", stderr)
        exit(1)
    }

    return Options(languages: languages, printToStdout: printToStdout)
}

// MARK: - Networking

let session: URLSession = {
    let config = URLSessionConfiguration.default
    config.httpAdditionalHeaders = [
        "User-Agent": "wikipedia-ios-topic-string-generator/1.0 (ios@wikimedia.org)"
    ]
    return URLSession(configuration: config)
}()

// Reads the error payload out of a MediaWiki API response, if present.
// With errorformat=html the API returns an "errors" array of objects with
// "code" and "html". Without an errorformat parameter it returns a single
// "error" object with "code" and "info".
func apiErrorMessage(from root: [String: Any]) -> String? {
    if let errors = root["errors"] as? [[String: Any]], !errors.isEmpty {
        let parts = errors.map { entry -> String in
            let code = entry["code"] as? String ?? "unknown"
            let text = (entry["html"] as? String) ?? (entry["text"] as? String) ?? ""
            return text.isEmpty ? code : "\(code): \(text)"
        }
        return parts.joined(separator: "; ")
    }
    if let error = root["error"] as? [String: Any] {
        let code = error["code"] as? String ?? "unknown"
        let info = error["info"] as? String ?? ""
        return info.isEmpty ? code : "\(code): \(info)"
    }
    return nil
}

func fetchJSONRoot(url: URL, queryItems: [URLQueryItem]) async throws -> [String: Any] {
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.queryItems = queryItems
    guard let requestURL = components?.url else {
        throw ScriptError("Could not build request URL.")
    }

    let (data, response) = try await session.data(from: requestURL)

    if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
        throw ScriptError("HTTP \(http.statusCode) for \(requestURL.absoluteString).")
    }

    guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        throw ScriptError("Response is not a JSON object for \(requestURL.absoluteString).")
    }

    if let apiError = apiErrorMessage(from: root) {
        throw ScriptError("API error for \(requestURL.absoluteString): \(apiError)")
    }

    return root
}

func fetchAvailableLanguageCodes() async throws -> [String] {
    let root = try await fetchJSONRoot(url: languagesAPIURL, queryItems: [
        URLQueryItem(name: "action", value: "query"),
        URLQueryItem(name: "format", value: "json"),
        URLQueryItem(name: "meta", value: "siteinfo"),
        URLQueryItem(name: "formatversion", value: "2"),
        URLQueryItem(name: "siprop", value: "languages")
    ])

    guard
        let query = root["query"] as? [String: Any],
        let languages = query["languages"] as? [[String: Any]]
    else {
        throw ScriptError("Unexpected siteinfo response shape.")
    }

    return languages.compactMap { $0["code"] as? String }
}

func fetchMessages(languageCode: String) async throws -> [String: String] {
    let root = try await fetchJSONRoot(url: topicsAPIURL, queryItems: [
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
    if FileManager.default.fileExists(atPath: url.path) {
        // A read failure must fail this language. Falling back to an empty
        // string here would rewrite the file with only the topic entries.
        existing = try String(contentsOf: url, usedEncoding: &encoding)
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
    let newEntries: [String] = msgKeys.compactMap { key in
        guard let value = translations[key], !replaced.contains(key) else {
            return nil
        }
        return buildEntry(key: key, value: value)
    }

    var result = lines.joined(separator: "\n")

    if !newEntries.isEmpty {
        let trimmed = result.trimmingCharacters(in: .newlines)
        let separator = trimmed.isEmpty ? "" : "\n\n"
        result = trimmed + separator + "\n" + newEntries.joined(separator: "\n\n") + "\n"
    }

    try result.write(to: url, atomically: true, encoding: encoding)
}

// MARK: - Resolve target languages

// True when the import script has already produced an app bundle for this
// MediaWiki code. Languages without one are skipped by default: adding topic
// strings for them would make the import script create a new bundle whose
// stringsdict is a full copy of the English one.
func hasAppBundle(for mediaWikiCode: String) -> Bool {
    let folder = twnLocaleToAppStoreConnectLocale[mediaWikiCode] ?? mediaWikiCode
    let stringsURL = resourcesURL
        .appendingPathComponent("\(folder).lproj")
        .appendingPathComponent("Localizable.strings")
    return FileManager.default.fileExists(atPath: stringsURL.path)
}

func existingLocalizationCodes() -> Set<String> {
    let contents = (try? FileManager.default.contentsOfDirectory(
        at: localizationsURL,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: .skipsHiddenFiles
    )) ?? []
    return Set(contents.filter { $0.pathExtension == "lproj" }.map { $0.deletingPathExtension().lastPathComponent })
}

func resolveTargetLanguages(options: Options) async throws -> [String] {
    guard options.languages.isEmpty else {
        for code in options.languages where !hasAppBundle(for: code) {
            fputs("Warning: '\(code)' has no app bundle under \(resourcesURL.path); the import script will not ship these strings.\n", stderr)
        }
        return options.languages
    }
    let existing = existingLocalizationCodes()
    let available = try await fetchAvailableLanguageCodes()
    return available
        .filter { existing.contains($0) && hasAppBundle(for: $0) }
        .sorted()
}

// MARK: - Main

let options = parseOptions()

do {
    let languages = try await resolveTargetLanguages(options: options)

    if languages.isEmpty {
        fputs("No matching languages found.\n", stderr)
        exit(1)
    }

    var updated = 0
    var skipped = 0
    var failed = 0

    for (offset, languageCode) in languages.enumerated() {
        // Pause before every request after the first, including after a
        // failure, so a rate-limited response doesn't skip the delay.
        if offset > 0 {
            try? await Task.sleep(nanoseconds: 500_000_000)
        }

        do {
            let translations = try await fetchMessages(languageCode: languageCode)

            guard !translations.isEmpty else {
                skipped += 1
                print("Skipping '\(languageCode)': no translations available.")
                continue
            }

            if options.printToStdout {
                for key in msgKeys {
                    if let value = translations[key] {
                        print(buildEntry(key: key, value: value))
                    }
                }
                exit(0)
            }

            let lprojURL = localizationsURL.appendingPathComponent("\(languageCode).lproj")
            guard FileManager.default.fileExists(atPath: lprojURL.path) else {
                throw ScriptError("No folder at \(lprojURL.path). This script only updates existing localization folders.")
            }
            let stringsURL = lprojURL.appendingPathComponent("Localizable.strings")

            try injectIntoStringsFile(at: stringsURL, translations: translations)
            updated += 1
            print("Updated \(stringsURL.path) (\(translations.count)/\(msgKeys.count) keys)")
        } catch {
            failed += 1
            fputs("Failed '\(languageCode)': \(error.localizedDescription)\n", stderr)
        }
    }

    print("Done: \(updated) updated, \(skipped) skipped, \(failed) failed.")
    exit(failed > 0 ? 1 : 0)
} catch {
    fputs("Error: \(error.localizedDescription)\n", stderr)
    exit(1)
}
