import Foundation

/// **THIS IS NOT PART OF THE MAIN APP - IT'S A COMMAND LINE UTILITY**

fileprivate var dictionaryRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[{][{])(:?[^{]*)(?:[}][}])", options: [])
    } catch {
        assertionFailure("Localization regex failed to compile")
    }
    return nil
}()

fileprivate var curlyBraceRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[{][{][a-z]+:)(:?[^{]*)(?:[}][}])", options: [.caseInsensitive])
    } catch {
        assertionFailure("Localization regex failed to compile")
    }
    return nil
}()


fileprivate var twnTokenRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[$])(:?[0-9]+)", options: [])
    } catch {
        assertionFailure("Localization token regex failed to compile")
    }
    return nil
}()

fileprivate var iOSTokenRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "%([0-9]*)\\$?([@dDuUxXoOfeEgGcCsSpaAF])", options: [])
    } catch {
        assertionFailure("Localization token regex failed to compile")
    }
    return nil
}()

fileprivate var mwLocalizedStringRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:WMLocalizedString\\(@\\\")(:?[^\"]+)(?:[^\\)]*\\))", options: [])
    } catch {
        assertionFailure("mwLocalizedStringRegex failed to compile")
    }
    return nil
}()

fileprivate var countPrefixRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(:?^[^\\=]+)(?:=)", options: [])
    } catch {
        assertionFailure("countPrefixRegex failed to compile")
    }
    return nil
}()

// lookup from translatewiki prefix to iOS-supported stringsdict key
let keysByPrefix = [
    "0":"zero",
    // "1":"one" digits on translatewiki mean only use the translation when the replacement number === that digit. On iOS one, two, and few are more generic. for example, the translation for one could map to 1, 21, 31, etc
    // "2":"two",
    // "3":"few"
    "zero":"zero",
    "one":"one",
    "two":"two",
    "few":"few",
    "many":"many",
    "other":"other"
]

extension String {
    var fullRange: NSRange {
        return NSRange(startIndex..<endIndex, in: self)
    }
    var escapedString: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }
    
    /* supportsOneEquals indicates that the language's singular translation on iOS is only valid for n=1. digits on translatewiki mean only use the translation when the replacement number === that digit. On iOS one, two, and few are more generic. for example, the translation for one could map to 1, 21, 31, etc. Only use 1= for one when the iOS definition matches the translatewiki definition for a given language. */
    func pluralDictionary(with keys: [String], tokens: [String: String], supportsOneEquals: Bool) -> NSDictionary? {
        // https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html#//apple_ref/doc/uid/10000171i-CH16-SW1
        guard let dictionaryRegex = dictionaryRegex else {
            return nil
        }
        var remainingKeys = keys
        let fullRange = self.fullRange
        let mutableDictionary = NSMutableDictionary(capacity: 5)
        let results = dictionaryRegex.matches(in: self, options: [], range: fullRange)
        let nsSelf = self as NSString

        // format is the full string with the plural tokens replaced by variables
        // it will be built by enumerating through the matches for the plural regex
        var format = ""
        var location = 0
        for result in results {
            // append the next part of the string after the last match and before this one
            format += nsSelf.substring(with: NSRange(location: location, length: result.range.location - location)).iOSNativeLocalization(tokens: tokens)
            location = result.range.location + result.range.length
            
            // get the contents of the match - the content between {{ and }}
            let contents = dictionaryRegex.replacementString(for: result, in: self, offset: 0, template: "$1")
             
            let components = contents.components(separatedBy: "|")
            
            let countOfComponents = components.count
            guard countOfComponents > 1 else {
                continue
            }

            let pluralPrefix = "PLURAL:"
            let firstComponent = components[0]
            guard firstComponent.hasPrefix(pluralPrefix) else {
                continue
            }

            if firstComponent == pluralPrefix {
                print("Incorrectly formatted plural: \(self)")
                abort()
            }
            
            let token = firstComponent.suffix(from: firstComponent.index(firstComponent.startIndex, offsetBy: 7)).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            let nsToken = (token as NSString)
            let tokenNumber = nsToken.substring(from: 1)
            
            guard
                let tokenInt = Int(tokenNumber),
                tokenInt > 0
            else {
                continue
            }
            
            let keyDictionary = NSMutableDictionary(capacity: 5)
            let formatValueType = tokens[tokenNumber] ?? "d"
            keyDictionary["NSStringFormatSpecTypeKey"] = "NSStringPluralRuleType"
            keyDictionary["NSStringFormatValueTypeKey"] = formatValueType
            
            guard let countPrefixRegex = countPrefixRegex else {
                abort()
            }
            
            var unlabeledComponents: [String] = []
            for component in components[1..<countOfComponents] {
                var keyForComponent: String?
                var actualComponent: String? = component
                guard let match = countPrefixRegex.firstMatch(in: component, options: [], range: component.fullRange) else {
                    if component.contains("=") {
                        print("Unsupported prefix: \(String(describing: component))")
                        abort()
                    }
                    unlabeledComponents.append(component)
                    continue
                }
                
                // Support for 0= 1= 2= zero= one= few= many=
                let numberString = countPrefixRegex.replacementString(for: match, in: component, offset: 0, template: "$1")
                if let key = (supportsOneEquals && (numberString == "1" || numberString == "one")) ? "one" : keysByPrefix[numberString] {
                    keyForComponent = key
                    remainingKeys = remainingKeys.filter({ (aKey) -> Bool in
                        return key != aKey
                    })
                    actualComponent = String(component.suffix(from: component.index(component.startIndex, offsetBy: match.range.length)))
                } else {
                    #if DEBUG
                    print("Translatewiki prefix \(numberString) not supported on iOS for this language. Ignoring \(String(describing: component))")
                    #endif
                }
                
                guard let keyToInsert = keyForComponent, let componentToInsert = actualComponent else {
                    continue
                }
                
                keyDictionary[keyToInsert] = componentToInsert.iOSNativeLocalization(tokens: tokens)
            }
            
            if let other = unlabeledComponents.last {
                keyDictionary["other"] = other.iOSNativeLocalization(tokens: tokens)
                
                for (keyIndex, component) in unlabeledComponents.enumerated() {
                    guard
                        keyIndex < unlabeledComponents.count - 1,
                        keyIndex < remainingKeys.count
                    else {
                        break
                    }
                    keyDictionary[remainingKeys[keyIndex]] = component.iOSNativeLocalization(tokens: tokens)
                }
            } else if keyDictionary["other"] == nil {
                if keyDictionary["many"] != nil {
                    keyDictionary["other"] = keyDictionary["many"]
                } else {
                    print("missing default translation")
                    abort()
                }
            }
        
            // set the variable name for the plural replacement
            let key = "v\(tokenInt)"
            // include the dictionary of possible replacements for the plural token
            mutableDictionary[key] = keyDictionary
            // append the variable name to the format string where the plural token used to be
            format += "%#@\(key)@"
        }
        // append the final part of the string after the last match
        format += nsSelf.substring(with: NSRange(location: location, length: nsSelf.length - location)).iOSNativeLocalization(tokens: tokens)
        mutableDictionary["NSStringLocalizedFormatKey"] = format
        return mutableDictionary
    }
    
    public func replacingMatches(fromRegex regex: NSRegularExpression, withFormat format: String) -> String {
        let nativeLocalization = NSMutableString(string: self)
        var offset = 0
        let fullRange = NSRange(location: 0, length: nativeLocalization.length)
        var index = 1
        regex.enumerateMatches(in: self, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            var token = regex.replacementString(for: result, in: nativeLocalization as String, offset: offset, template: "$1")
            // If the token doesn't have an index, give it one
            // This allows us to support unordered tokens for single token strings
            if token == "" {
                token = "\(index)"
            }
            let replacement = String(format: format, token)
            let replacementRange = NSRange(location: result.range.location + offset, length: result.range.length)
            nativeLocalization.replaceCharacters(in: replacementRange, with: replacement)
            offset += (replacement as NSString).length - result.range.length
            index += 1
        }
        return nativeLocalization as String
    }
    
    public func replacingMatches(fromTokenRegex regex: NSRegularExpression, withFormat format: String, tokens: [String: String]) -> String {
        let nativeLocalization = NSMutableString(string: self)
        var offset = 0
        let fullRange = NSRange(location: 0, length: nativeLocalization.length)
        regex.enumerateMatches(in: self, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            let token = regex.replacementString(for: result, in: nativeLocalization as String, offset: offset, template: "$1")
            let replacement = String(format: format, token, tokens[token] ?? "@")
            let replacementRange = NSRange(location: result.range.location + offset, length: result.range.length)
            nativeLocalization.replaceCharacters(in: replacementRange, with: replacement)
            offset += (replacement as NSString).length - result.range.length
        }
        return nativeLocalization as String
    }
    
    func iOSNativeLocalization(tokens: [String: String]) -> String {
        guard let tokenRegex = twnTokenRegex, let braceRegex = curlyBraceRegex else {
            return ""
        }
        return self.replacingMatches(fromRegex: braceRegex, withFormat: "%@").replacingMatches(fromTokenRegex: tokenRegex, withFormat: "%%%@$%@", tokens: tokens)
    }
    
    var twnNativeLocalization: String {
        guard let tokenRegex = iOSTokenRegex else {
            return ""
        }
        return self.replacingMatches(fromRegex: tokenRegex, withFormat: "$%@")
    }
    
    var iOSTokenDictionary: [String: String] {
        guard let iOSTokenRegex = iOSTokenRegex else {
            print("Unable to compile iOS token regex")
            abort()
        }
        var tokenDictionary = [String:String]()
        iOSTokenRegex.enumerateMatches(in: self, options: [], range:self.fullRange, using: { (result, flags, stop) in
            guard let result = result else {
                return
            }
            var number = iOSTokenRegex.replacementString(for: result, in: self as String, offset: 0, template: "$1")
            // treat an un-numbered token as 1
            if number == "" {
                number = "1"
            }
            let token = iOSTokenRegex.replacementString(for: result, in: self as String, offset: 0, template: "$2")
            if tokenDictionary[number] == nil {
                tokenDictionary[number] = token
            } else if token != tokenDictionary[number] {
                print("Internal token mismatch: \(self)")
                abort()
            }
        })
        return tokenDictionary
    }
}

func writeStrings(fromDictionary dictionary: NSDictionary, toFile: String) throws {
    var shouldWrite = true
    
    if let existingDictionary = NSDictionary(contentsOfFile: toFile) {
        shouldWrite = existingDictionary.count != dictionary.count
        if !shouldWrite {
            for (key, value) in dictionary {
                guard let value = value as? String, let existingValue = existingDictionary[key] as? NSString else {
                    shouldWrite = true
                    break
                }
                shouldWrite = !existingValue.isEqual(to: value)
                if shouldWrite {
                    break
                }
            }
        }
    }
    
    
    guard shouldWrite else {
        return
    }
    
    let folder = (toFile as NSString).deletingLastPathComponent
    do {
        try FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
    } catch { }
    let output = dictionary.descriptionInStringsFileFormat
    try output.write(toFile: toFile, atomically: true, encoding: .utf16) // From Apple: Note: It is recommended that you save strings files using the UTF-16 encoding, which is the default encoding for standard strings files. It is possible to create strings files using other property-list formats, including binary property-list formats and XML formats that use the UTF-8 encoding, but doing so is not recommended. For more information about Unicode and its text encodings, go to http://www.unicode.org/ or http://en.wikipedia.org/wiki/Unicode.
}

// See "Localized Metadata" section here: https://docs.fastlane.tools/actions/deliver/
func fileURLForFastlaneMetadataFolder(for locale: String) -> URL {
    return URL(fileURLWithPath:"\(path)/fastlane/metadata/\(locale)")
}

func fileURLForFastlaneMetadataFile(_ file: String, for locale: String) -> URL {
    return fileURLForFastlaneMetadataFolder(for: locale).appendingPathComponent(file)
}

let defaultAppStoreMetadataLocale = "en-us"
func writeFastlaneMetadata(_ metadata: Any?, to filename: String, for locale: String) throws {
    let metadataFileURL = fileURLForFastlaneMetadataFile(filename, for: locale)
    guard let metadata = metadata as? String, metadata.count > 0 else {
        let defaultDescriptionFileURL = fileURLForFastlaneMetadataFile(filename, for: defaultAppStoreMetadataLocale)
        let fm = FileManager.default
        try fm.removeItem(at: metadataFileURL)
        try fm.copyItem(at: defaultDescriptionFileURL, to: metadataFileURL)
        return
    }
    try metadata.write(to: metadataFileURL, atomically: true, encoding: .utf8)
}

func writeTWNStrings(fromDictionary dictionary: [String: String], toFile: String, escaped: Bool) throws {
    var output = ""
    let sortedDictionary = dictionary.sorted(by: { (kv1, kv2) -> Bool in
        return kv1.key < kv2.key
    })
    for (key, value) in sortedDictionary {
        output.append("\"\(key)\" = \"\(escaped ? value.escapedString : value)\";\n")
    }
    
    try output.write(toFile: toFile, atomically: true, encoding: .utf8)
}

func exportLocalizationsFromSourceCode(_ path: String) {
    let iOSENPath = "\(path)/Wikipedia/iOS Native Localizations/en.lproj/Localizable.strings"
    let twnQQQPath = "\(path)/Wikipedia/Localizations/qqq.lproj/Localizable.strings"
    let twnENPath = "\(path)/Wikipedia/Localizations/en.lproj/Localizable.strings"
    guard let iOSEN = NSDictionary(contentsOfFile: iOSENPath) else {
        print("Unable to read \(iOSENPath)")
        abort()
    }
    
    let twnQQQ = NSMutableDictionary()
    let twnEN = NSMutableDictionary()
    
    do {
        let commentSet = CharacterSet(charactersIn: "/* ")
        let quoteSet = CharacterSet(charactersIn: "\"")
        let string = try String(contentsOfFile: iOSENPath)
        let lines = string.components(separatedBy: .newlines)
        var currentComment: String?
        var currentKey: String?
        var commentsByKey = [String: String]()
        for line in lines {
            let cleanedLine = line.trimmingCharacters(in: .whitespaces)
            if cleanedLine.hasPrefix("/*") {
                currentComment = cleanedLine.trimmingCharacters(in: commentSet)
                currentKey = nil
            } else if currentComment != nil {
                let quotesRemoved = cleanedLine.trimmingCharacters(in: quoteSet)
                
                if let range = quotesRemoved.range(of: "\" = \"") {
                    currentKey = String(quotesRemoved.prefix(upTo: range.lowerBound))
                }
            }
            if let key = currentKey, let comment =  currentComment {
                commentsByKey[key] = comment
            }
        }
        
        for (key, comment) in commentsByKey {
            twnQQQ[key] = comment.twnNativeLocalization
        }
        try writeTWNStrings(fromDictionary: twnQQQ as! [String: String], toFile: twnQQQPath, escaped: false)
        
        for (key, value) in iOSEN {
            guard let value = value as? String, let key = key as? String  else {
                continue
            }
            twnEN[key] = value.twnNativeLocalization
        }
        try writeTWNStrings(fromDictionary: twnEN  as! [String: String], toFile: twnENPath, escaped: true)
    } catch let error {
        print("Error exporting localizations: \(error)")
        abort()
    }
}

let locales: Set<String> =  {
    var identifiers = Locale.availableIdentifiers
    if let filenames = try? FileManager.default.contentsOfDirectory(atPath: "\(path)/Wikipedia/iOS Native Localizations") {
        let additional = filenames.compactMap { $0.components(separatedBy: ".").first?.lowercased() }
        identifiers += additional
    }
    identifiers += ["ku"] // iOS 13 added support for ku but macOS 10.14 doesn't include it, add it manually. This line can be removed when macOS 10.15 ships.
    return Set<String>(identifiers)
}()

// See supportsOneEquals documentation. Utilized this list: https://unicode-org.github.io/cldr-staging/charts/37/supplemental/language_plural_rules.html to verify languages where that applies for the cardinal -> one rule
let localesWhereMediaWikiPluralRulesDoNotMatchiOSPluralRulesForOne = {
    return Set<String>(["be", "bs", "br", "ceb", "tzm", "hr", "fil", "is", "lv", "lt", "dsb", "mk", "gv", "prg", "ru", "gd", "sr", "sl", "uk", "hsb"]).intersection(locales)
}()

func localeIsAvailable(_ locale: String) -> Bool {
    let prefix = locale.components(separatedBy: "-").first ?? locale
    return locales.contains(prefix)
}

func importLocalizationsFromTWN(_ path: String) {
    let enPath = "\(path)/Wikipedia/iOS Native Localizations/en.lproj/Localizable.strings"
    
    guard let enDictionary = NSDictionary(contentsOfFile: enPath) as? [String: String] else {
        print("Unable to read \(enPath)")
        abort()
    }
    
    var enTokensByKey = [String: [String: String]]()
    
    for (key, value) in enDictionary {
        enTokensByKey[key] = value.iOSTokenDictionary
    }
    
    let fm = FileManager.default
    do {
        let keysByLanguage = ["pl": ["one", "few"], "sr": ["one", "few", "many"], "ru": ["one", "few", "many"]]
        let defaultKeys = ["one"]
        let appStoreMetadataLocales: [String: [String]] = [
            "da": ["da"],
            "de": ["de-de"],
            "el": ["el"],
            // "en": ["en-au", "en-ca", "en-gb"],
            "es": ["es-mx", "es-es"],
            "fi": ["fi"],
            "fr": ["fr-ca", "fr-fr"],
            "id": ["id"],
            "it": ["it"],
            "ja": ["ja"],
            "ko": ["ko"],
            "ms": ["ms"],
            "nl": ["nl-nl"],
            "no": ["no"],
            "pt": ["pt-br", "pt-pt"],
            "ru": ["ru"],
            "sv": ["sv"],
            "th": ["th"],
            "tr": ["tr"],
            "vi": ["vi"],
            "zh-hans": ["zh-hans"],
            "zh-hant": ["zh-hant"]
        ]
        
        let contents = try fm.contentsOfDirectory(atPath: "\(path)/Wikipedia/Localizations")
        var pathsForEnglishPlurals: [String] = [] // write english plurals to these paths as placeholders
        var englishPluralDictionary: NSMutableDictionary?
        for filename in contents {
            guard let locale = filename.components(separatedBy: ".").first?.lowercased() else {
                continue
            }
            
            let localeFolder = "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj"

            guard localeIsAvailable(locale), let twnStrings = NSDictionary(contentsOfFile: "\(path)/Wikipedia/Localizations/\(locale).lproj/Localizable.strings") else {
                try? fm.removeItem(atPath: localeFolder)
                continue
            }
            
            let stringsDictFilePath = "\(localeFolder)/Localizable.stringsdict"
            let stringsFilePath = "\(localeFolder)/Localizable.strings"
            
            let stringsDict = NSMutableDictionary(capacity: twnStrings.count)
            let strings = NSMutableDictionary(capacity: twnStrings.count)
            for (key, value) in twnStrings {
                guard let twnString = value as? String, let key = key as? String, let enTokens = enTokensByKey[key] else {
                    continue
                }
                let nativeLocalization = twnString.iOSNativeLocalization(tokens: enTokens)
                let nativeLocalizationTokens = nativeLocalization.iOSTokenDictionary
                guard nativeLocalizationTokens == enTokens else {
                    #if DEBUG
                    print("Mismatched tokens in \(locale) for \(key):\n\(enDictionary[key] ?? "")\n\(nativeLocalization)")
                    #endif
                    continue
                }
                if twnString.contains("{{PLURAL:") {
                    let lang = locale.components(separatedBy: "-").first ?? ""
                    let keys = keysByLanguage[lang] ?? defaultKeys
                    let supportsOneEquals = !localesWhereMediaWikiPluralRulesDoNotMatchiOSPluralRulesForOne.contains(lang)
                    stringsDict[key] = twnString.pluralDictionary(with: keys, tokens:enTokens, supportsOneEquals: supportsOneEquals)
                    strings[key] = nativeLocalization
                } else {
                    strings[key] = nativeLocalization
                }
            }
            if locale != "en" { // only write the english plurals, skip the main file
                if strings.count > 0 {
                    try writeStrings(fromDictionary: strings, toFile: stringsFilePath)
                } else {
                    try? fm.removeItem(atPath: stringsFilePath)
                }
            } else {
                englishPluralDictionary = stringsDict
            }
            
           
            if let metadataLocales = appStoreMetadataLocales[locale] {
                for metadataLocale in metadataLocales {
                    let folderURL = fileURLForFastlaneMetadataFolder(for: metadataLocale)
                    try fm.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
                    
                    let infoPlistPath = "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/InfoPlist.strings"
                    let infoPlist = NSDictionary(contentsOfFile: infoPlistPath)
                    
                    try? writeFastlaneMetadata(strings["app-store-short-description"], to: "description.txt", for: metadataLocale)
                    try? writeFastlaneMetadata(strings["app-store-keywords"], to: "keywords.txt", for: metadataLocale)
                    try? writeFastlaneMetadata(nil, to: "marketing_url.txt", for: metadataLocale) // use nil to copy from en-US. all fields need to be specified.
                    try? writeFastlaneMetadata(infoPlist?["CFBundleDisplayName"], to: "name.txt", for: metadataLocale)
                    try? writeFastlaneMetadata(nil, to: "privacy_url.txt", for: metadataLocale) // use nil to copy from en-US. all fields need to be specified.
                    try? writeFastlaneMetadata(nil, to: "promotional_text.txt", for: metadataLocale) // use nil to copy from en-US. all fields need to be specified.
                    try? writeFastlaneMetadata(nil, to: "release_notes.txt", for: metadataLocale) // use nil to copy from en-US. all fields need to be specified.
                    try? writeFastlaneMetadata(strings["app-store-subtitle"], to: "subtitle.txt", for: metadataLocale)
                    try? writeFastlaneMetadata(nil, to: "support_url.txt", for: metadataLocale) // use nil to copy from en-US. all fields need to be specified.
                }
            
            } else {
                let folderURL = fileURLForFastlaneMetadataFolder(for: locale)
                try? fm.removeItem(at: folderURL)
            }
            
            if stringsDict.count > 0 {
                stringsDict.write(toFile: stringsDictFilePath, atomically: true)
            } else {
                pathsForEnglishPlurals.append(stringsDictFilePath)
            }
            
        }
        
        for stringsDictFilePath in pathsForEnglishPlurals {
            englishPluralDictionary?.write(toFile: stringsDictFilePath, atomically: true)
        }
        
    } catch let error {
        print("Error importing localizations: \(error)")
        abort()
    }
}

// Code that updated source translations
//  var replacements = [String: String]()
// for (key, comment) in qqq {
//     guard let value = en[key] else {
//         continue
//     }
//     replacements[key] = "WMFLocalizedStringWithDefaultValue(@\"\(key.escapedString)\", nil, NSBundle.mainBundle, @\"\(value.iOSNativeLocalization.escapedString)\", \"\(comment.escapedString)\")"
// }
//
// let codePath = "WMF Framework"
// let contents = try FileManager.default.contentsOfDirectory(atPath: codePath)
//  guard let mwLocalizedStringRegex = mwLocalizedStringRegex else {
//      abort()
//  }
//  for filename in contents {
//      do {
//             let path = codePath + "/" + filename
//          let string = try String(contentsOfFile: path)
//          //let string = try String(contentsOf: #fileLiteral(resourceName: "WMFContentGroup+WMFFeedContentDisplaying.m"))
//          let mutableString = NSMutableString(string: string)
//          var offset = 0
//          let fullRange = NSRange(location: 0, length: mutableString.length)
//          mwLocalizedStringRegex.enumerateMatches(in: string, options: [], range: fullRange) { (result, flags, stop) in
//              guard let result = result else {
//                  return
//              }
//              let key = mwLocalizedStringRegex.replacementString(for: result, in: mutableString as String, offset: offset, template: "$1")
//              guard let replacement = replacements[key] else {
//                  return
//              }
//              let replacementRange = NSRange(location: result.range.location + offset, length: result.range.length)
//              mutableString.replaceCharacters(in: replacementRange, with: replacement)
//              offset += (replacement as NSString).length - replacementRange.length
//          }
//             try mutableString.write(toFile: path, atomically: true, encoding: String.Encoding.utf8.rawValue)
//      } catch { }
// }
