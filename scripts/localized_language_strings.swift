/// Generates Wikipedia site language specific localized strings extension for CommonStrings.swift
/// Usage: `swift ./scripts/localized_language_strings.swift` from root `wikipedia-ios` directory

import Foundation

// Nested Types
struct Language: Codable {
    let canonical_name: String
    let code: String
}

enum LanguageError: Error {
    case invalidDataPath
}

// Properties
let jsonPath = FileManager.default.currentDirectoryPath + "/Wikipedia/assets/languages.json"

do {
    guard let jsonData = FileManager.default.contents(atPath: jsonPath) else {
        throw LanguageError.invalidDataPath
    }
    let languages = try JSONDecoder().decode([Language].self, from: jsonData)
    
    // Generate extension
    let indentation = "    "
    print("// To support grammatically correct translations, where grammatical gender and order affect the resulting string,")
    print("// generate strings for all supported Wikipedia languages to be translated per app localized language.\n")
    print("@objc public extension CommonStrings {\n")

    print("\(String(repeating: indentation, count: 1))typealias LanguageCode = String\n")

    print("\(String(repeating: indentation, count: 1))// Generic\n")
    print("\(String(repeating: indentation, count: 1))static let fromWikipedia = WMFLocalizedString(\"from-wikipedia\", value: \"From Wikipedia\", comment: \"Text displayed to indicate content is from Wikipedia when the specific language wikipedia is unknown.\")")
    print("\(String(repeating: indentation, count: 1))static let onWikipedia = WMFLocalizedString(\"on-wikipedia\", value: \"On Wikipedia\", comment: \"Text displayed to indicate content is on Wikipedia when the specific language wikipedia is unknown.\")\n")
    
    print("\(String(repeating: indentation, count: 1))// Language Specific\n")
    print("\(String(repeating: indentation, count:1))static let fromLanguageWikipedia: [LanguageCode: String] = [")
    languages.forEach { language in
        print("\(String(repeating: indentation, count:2)) \"\(language.code)\": WMFLocalizedString(\"from-\(language.code)-wikipedia\", value: \"From \(language.canonical_name) Wikipedia\", comment: \"Text displayed to indicate content is from \(language.canonical_name) Wikipedia.\"),")
    }
    print("\(indentation)]")

    print("\n\(String(repeating: indentation, count:1))static let onLanguageWikipedia: [LanguageCode: String] = [")
    languages.forEach { language in
        print("\(String(repeating: indentation, count:2)) \"\(language.code)\": WMFLocalizedString(\"on-\(language.code)-wikipedia\", value: \"On \(language.canonical_name) Wikipedia\", comment: \"Text displayed to indicate content is on \(language.canonical_name) Wikipedia.\"),")
    }
    print("\(indentation)]")
    
    print("\n\(String(repeating: indentation, count:1))static let talkPageActiveConversations: [LanguageCode: String] = [")
    languages.forEach { language in
        print("\(String(repeating: indentation, count:2)) \"\(language.code)\": WMFLocalizedString(\"talk-page-info-active-conversations-\(language.code)\", value: \"Active conversations on \(language.canonical_name) Wikipedia\", comment: \"This information label is displayed at the top of a talk page discussion list.\"),")
    }
    print("\(indentation)]")
    
    print("\n\(String(repeating: indentation, count:1))static let topReadHeader: [LanguageCode: String] = [")
    languages.forEach { language in
        print("\(String(repeating: indentation, count:2)) \"\(language.code)\": WMFLocalizedString(\"top-read-header-with-language-\(language.code)\", value: \"\(language.canonical_name) Wikipedia\", comment: \"\(language.canonical_name) Wikipedia {{Identical|Wikipedia}}\"),")
    }
    print("\(indentation)]")
    
    print("\n\(String(repeating: indentation, count:1))static let exploreNearbySubheading: [LanguageCode: String] = [")
    languages.forEach { language in
        print("\(String(repeating: indentation, count:2)) \"\(language.code)\": WMFLocalizedString(\"explore-nearby-sub-heading-your-location-from-\(language.code)-wikipedia\", value: \"Your location from \(language.canonical_name) Wikipedia\", comment: \"Subtext beneath the 'Places near' header when showing articles near the user's current location.\"),")
    }
    print("\(indentation)]")
    print("\n}")
}
catch let error {
    print("Error: \(error)")
}
