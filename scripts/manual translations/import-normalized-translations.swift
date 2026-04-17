#!/usr/bin/env swift
//
// import-normalized-translations.swift
//
// Reads normalized CSV files from a given directory and inserts translations
// into the appropriate Wikipedia/Localizations/{lproj}/Localizable.strings file.
//
// CSV format — required columns (order doesn't matter):
//   English       The original English string (informational, not used for insertion)
//   Translation   The translated string to insert
//   Key           The Localizable.strings key (e.g. "translations-key-hello")
//   File          The target .lproj directory name (e.g. "es.lproj")
//
// Usage:
//   swift "scripts/manual translations/import-normalized-translations.swift" <path-to-csv-directory>
//
// Example:
//   swift "scripts/manual translations/import-normalized-translations.swift" "scripts/manual translations/normalized/"
//

import Foundation

// MARK: - CSV Parsing

/// Parses a CSV string into a 2D array of fields.
/// Handles RFC 4180: quoted fields with embedded commas, newlines, and doubled quotes.
func parseCSV(_ content: String) -> [[String]] {
    var rows: [[String]] = []
    var currentRow: [String] = []
    var currentField = ""
    var inQuotes = false
    var i = content.startIndex

    while i < content.endIndex {
        let c = content[i]
        let next = content.index(after: i)

        if inQuotes {
            if c == "\"" && next < content.endIndex && content[next] == "\"" {
                // Escaped double-quote inside a quoted field
                currentField.append("\"")
                i = content.index(after: next)
                continue
            } else if c == "\"" {
                inQuotes = false
            } else {
                currentField.append(c)
            }
        } else {
            switch c {
            case "\"":
                inQuotes = true
            case ",":
                currentRow.append(currentField)
                currentField = ""
            case "\r":
                break // skip bare CR; \r\n is handled by \n
            case "\n":
                currentRow.append(currentField)
                currentField = ""
                if currentRow.contains(where: { !$0.isEmpty }) {
                    rows.append(currentRow)
                }
                currentRow = []
            default:
                currentField.append(c)
            }
        }
        i = content.index(after: i)
    }

    // Flush the last field and row
    currentRow.append(currentField)
    if currentRow.contains(where: { !$0.isEmpty }) {
        rows.append(currentRow)
    }

    return rows
}

// MARK: - Localizable.strings Parsing

struct StringsFile {
    var headerLines: [String]                                              // Leading // comment lines + blank separator
    var entries: [(key: String, line: String, precedingComments: [String])] // Key-value pairs in sorted order
    var trailingLines: [String]                                            // Comment/blank lines after the last entry
    let trailingNewline: Bool
}

/// Extracts the key from a Localizable.strings line of the form: "key" = "value";
func extractKey(from line: String) -> String? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    guard trimmed.hasPrefix("\"") else { return nil }
    var key = ""
    var i = trimmed.index(after: trimmed.startIndex)
    while i < trimmed.endIndex {
        let c = trimmed[i]
        if c == "\\" {
            let ni = trimmed.index(after: i)
            if ni < trimmed.endIndex {
                key.append(c)
                key.append(trimmed[ni])
                i = trimmed.index(after: ni)
                continue
            }
        } else if c == "\"" {
            return key
        }
        key.append(c)
        i = trimmed.index(after: i)
    }
    return nil
}

/// Splits the file into a header block (// comments + blank lines at the top)
/// and the list of key-value entries.
func parseStringsFile(_ content: String) -> StringsFile {
    var lines = content.components(separatedBy: "\n")
    let trailingNewline = content.hasSuffix("\n")
    if trailingNewline, lines.last == "" {
        lines.removeLast()
    }

    var headerLines: [String] = []
    var entries: [(key: String, line: String, precedingComments: [String])] = []
    var trailingLines: [String] = []
    var pastHeader = false
    var pendingComments: [String] = []

    for line in lines {
        if !pastHeader {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("//") || trimmed.isEmpty {
                headerLines.append(line)
            } else {
                pastHeader = true
                if let key = extractKey(from: line) {
                    entries.append((key: key, line: line, precedingComments: pendingComments))
                    pendingComments = []
                } else {
                    pendingComments.append(line)
                }
            }
        } else {
            if let key = extractKey(from: line) {
                entries.append((key: key, line: line, precedingComments: pendingComments))
                pendingComments = []
            } else {
                pendingComments.append(line)
            }
        }
    }
    trailingLines = pendingComments

    return StringsFile(headerLines: headerLines, entries: entries, trailingLines: trailingLines, trailingNewline: trailingNewline)
}

/// Reconstructs a Localizable.strings file from its parsed representation.
func serialize(_ file: StringsFile) -> String {
    var allLines = file.headerLines
    for entry in file.entries {
        allLines += entry.precedingComments
        allLines.append(entry.line)
    }
    allLines += file.trailingLines
    var result = allLines.joined(separator: "\n")
    if file.trailingNewline { result += "\n" }
    return result
}

// MARK: - Strings Escaping

/// Escapes a string value for use inside a Localizable.strings quoted literal.
func escapeForStrings(_ value: String) -> String {
    return value
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")
        .replacingOccurrences(of: "\n", with: "\\n")
        .replacingOccurrences(of: "\r", with: "\\r")
        .replacingOccurrences(of: "\t", with: "\\t")
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count >= 2 else {
    fputs("Usage: swift \"scripts/manual translations/import-normalized-translations.swift\" <csv-directory>\n", stderr)
    fputs("Example: swift \"scripts/manual translations/import-normalized-translations.swift\" \"scripts/manual translations/normalized/\"\n", stderr)
    exit(1)
}

let csvDirPath = args[1]

// Resolve script directory, handling both absolute and relative invocation paths.
let scriptDir: URL = {
    let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    return URL(fileURLWithPath: #file, relativeTo: cwd).standardized.deletingLastPathComponent()
}()

let localizationsBase = scriptDir
    .appendingPathComponent("../../Wikipedia/Localizations")
    .standardized

let fm = FileManager.default

guard let allFiles = try? fm.contentsOfDirectory(atPath: csvDirPath) else {
    fputs("Error: Cannot read directory: \(csvDirPath)\n", stderr)
    exit(1)
}

let csvFiles = allFiles.filter { $0.hasSuffix(".csv") }.sorted()
guard !csvFiles.isEmpty else {
    fputs("Error: No CSV files found in \(csvDirPath)\n", stderr)
    exit(1)
}

print("Found \(csvFiles.count) CSV file(s) in \(csvDirPath)\n")

var totalInserted = 0
var skipped: [(key: String, file: String)] = []
var errors: [String] = []

for csvFile in csvFiles {
    let csvPath = URL(fileURLWithPath: csvDirPath).appendingPathComponent(csvFile).path
    print("Processing: \(csvFile)")

    guard let csvContent = try? String(contentsOfFile: csvPath, encoding: .utf8) else {
        errors.append("Could not read CSV file: \(csvFile)")
        continue
    }

    let rows = parseCSV(csvContent.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n"))
    guard rows.count >= 2 else {
        errors.append("CSV '\(csvFile)' has no data rows (empty or header-only)")
        continue
    }

    // Locate required columns by name (case-sensitive)
    let header = rows[0].map { $0.trimmingCharacters(in: .whitespaces) }
    guard
        let translationIdx = header.firstIndex(of: "Translation"),
        let keyIdx = header.firstIndex(of: "Key"),
        let fileIdx = header.firstIndex(of: "File")
    else {
        errors.append("CSV '\(csvFile)' is missing required columns. Expected: English, Translation, Key, File. Found: \(header.joined(separator: ", "))")
        continue
    }

    // Group all entries in this CSV by target lproj so we only read/write each file once.
    var rowsByLproj: [String: [(key: String, translation: String)]] = [:]
    for row in rows.dropFirst() {
        let maxIdx = max(translationIdx, keyIdx, fileIdx)
        guard row.count > maxIdx else { continue }
        let key = row[keyIdx].trimmingCharacters(in: .whitespaces)
        let translation = row[translationIdx]
        let lproj = row[fileIdx].trimmingCharacters(in: .whitespaces)
        if key.isEmpty || translation.isEmpty || lproj.isEmpty {
            let rowNum = rows.firstIndex(where: { $0 == row }).map { $0 + 1 } ?? -1
            print("  ⚠️  SKIP: Row \(rowNum) in '\(csvFile)' is missing Key, Translation, or File — skipping")
            skipped.append((key: key.isEmpty ? "(empty key)" : key, file: lproj.isEmpty ? "(no file)" : "\(lproj)/Localizable.strings"))
            continue
        }
        rowsByLproj[lproj, default: []].append((key: key, translation: translation))
    }

    for (lproj, newEntries) in rowsByLproj.sorted(by: { $0.key < $1.key }) {
        let lprojDirPath = localizationsBase.appendingPathComponent(lproj).path
        let stringsPath = localizationsBase
            .appendingPathComponent(lproj)
            .appendingPathComponent("Localizable.strings").path

        guard fm.fileExists(atPath: lprojDirPath) else {
            errors.append("Directory not found: \(lprojDirPath)")
            continue
        }

        guard let content = try? String(contentsOfFile: stringsPath, encoding: .utf8) else {
            errors.append("Could not read: \(stringsPath)")
            continue
        }

        var stringsFile = parseStringsFile(content)

        for (key, translation) in newEntries {
            if stringsFile.entries.contains(where: { $0.key == key }) {
                print("  ⚠️  SKIP: '\(key)' already exists in \(lproj)/Localizable.strings")
                skipped.append((key: key, file: "\(lproj)/Localizable.strings"))
                continue
            }

            let escapedKey = escapeForStrings(key)
            let escapedValue = escapeForStrings(translation)
            let newLine = "\"\(escapedKey)\" = \"\(escapedValue)\";"

            // Insert at the correct alphabetical position
            let insertIdx = stringsFile.entries.firstIndex(where: { $0.key > key })
                ?? stringsFile.entries.endIndex
            stringsFile.entries.insert((key: key, line: newLine, precedingComments: []), at: insertIdx)
            totalInserted += 1
            print("  ✅ Inserted: '\(key)' → \(lproj)/Localizable.strings")
        }

        do {
            try serialize(stringsFile).write(toFile: stringsPath, atomically: true, encoding: .utf8)
        } catch {
            errors.append("Could not write \(stringsPath): \(error.localizedDescription)")
        }
    }
}

// Summary
print("\n--- Summary ---")
print("✅ Inserted: \(totalInserted)")
print("⚠️  Skipped:  \(skipped.count)")
for s in skipped {
    print("   - \(s.key) in \(s.file)")
}
if !errors.isEmpty {
    print("❌ Errors:   \(errors.count)")
    for e in errors {
        print("   - \(e)")
    }
}
