import Foundation

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
        return try NSRegularExpression(pattern: "(?:[%])(:?[0-9]+)(?:[$])(:?[@dDuUxXoOfeEgGcCsSpaAF])", options: [])
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
        return try NSRegularExpression(pattern: "(:?^[0-9]+)(?:=)", options: [])
    } catch {
        assertionFailure("countPrefixRegex failed to compile")
    }
    return nil
}()

let keysByPrefix = ["0":"zero", "1":"one", "2":"two", "3":"few"]
extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: (self as NSString).length)
    }
    var escapedString: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }
    func pluralDictionary(with keys: [String], tokens: [String: String]) -> NSDictionary? {
        //https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html#//apple_ref/doc/uid/10000171i-CH16-SW1
        guard let dictionaryRegex = dictionaryRegex else {
            return nil
        }
        var remainingKeys = keys
        let fullRange = self.fullRange
        let mutableDictionary = NSMutableDictionary(capacity: 5)
        let results = dictionaryRegex.matches(in: self, options: [], range: fullRange)
        
        guard results.count == 1 else {
            // we only support strings with a single plural
            return nil
        }
        
        guard let result = results.first else {
            return nil
        }
        
        let contents = dictionaryRegex.replacementString(for: result, in: self, offset: 0, template: "$1")
        
        let components = contents.components(separatedBy: "|")
        
        let countOfComponents = components.count
        guard countOfComponents > 1 else {
            return nil
        }
        
        let firstComponent = components[0]
        guard firstComponent.hasPrefix("PLURAL:") else {
            return nil
        }
        
        let token = firstComponent.suffix(from: firstComponent.index(firstComponent.startIndex, offsetBy: 7))
        guard (token as NSString).length == 2 else {
            return nil
        }
        
        let range = result.range
        let nsSelf = self as NSString
        let keyDictionary = NSMutableDictionary(capacity: 5)
        let formatValueType = tokens["1"] ?? "d"
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
                unlabeledComponents.append(component)
                continue
            }
            
            // Support for 0= 1= 2=
            let numberString = countPrefixRegex.replacementString(for: match, in: component, offset: 0, template: "$1")
            if let key = keysByPrefix[numberString] {
                keyForComponent = key
                remainingKeys = remainingKeys.filter({ (aKey) -> Bool in
                    return key != aKey
                })
                actualComponent = String(component.suffix(from: component.index(component.startIndex, offsetBy: match.range.length)))
            } else {
                print("Unsupported prefix. Ignoring \(String(describing: component))")
            }
            
            guard let keyToInsert = keyForComponent, let componentToInsert = actualComponent else {
                continue
            }
            
            keyDictionary[keyToInsert] = nsSelf.replacingCharacters(in:range, with: componentToInsert).iOSNativeLocalization(tokens: tokens)
        }
        
        guard let other = unlabeledComponents.last else {
            print("missing base translation for \(keys) \(tokens)")
            abort()
        }
        keyDictionary["other"] = nsSelf.replacingCharacters(in:range, with: other).iOSNativeLocalization(tokens: tokens)
        
        var keyIndex = 0
        for component in unlabeledComponents[0..<(unlabeledComponents.count - 1)] {
            guard keyIndex < remainingKeys.count else {
                break
            }
            keyDictionary[remainingKeys[keyIndex]] = nsSelf.replacingCharacters(in:range, with: component).iOSNativeLocalization(tokens: tokens)
            keyIndex += 1
        }
        
        
        let key = "v0"
        mutableDictionary[key] = keyDictionary
        let replacement = "%#@\(key)@"
        mutableDictionary["NSStringLocalizedFormatKey"] = replacement
        return mutableDictionary
    }
    
    public func replacingMatches(fromRegex regex: NSRegularExpression, withFormat format: String) -> String {
        let nativeLocalization = NSMutableString(string: self)
        var offset = 0
        let fullRange = NSRange(location: 0, length: nativeLocalization.length)
        regex.enumerateMatches(in: self, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            let token = regex.replacementString(for: result, in: nativeLocalization as String, offset: offset, template: "$1")
            let replacement = String(format: format, token)
            let replacementRange = NSRange(location: result.range.location + offset, length: result.range.length)
            nativeLocalization.replaceCharacters(in: replacementRange, with: replacement)
            offset += (replacement as NSString).length - result.range.length
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
            let number = iOSTokenRegex.replacementString(for: result, in: self as String, offset: 0, template: "$1")
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
        if (!shouldWrite) {
            for (key, value) in dictionary {
                guard let value = value as? String, let existingValue = existingDictionary[key] as? NSString else {
                    shouldWrite = true
                    break
                }
                shouldWrite = !existingValue.isEqual(to: value)
                if (shouldWrite) {
                    break;
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
    try output.write(toFile: toFile, atomically: true, encoding: .utf16) //From Apple: Note: It is recommended that you save strings files using the UTF-16 encoding, which is the default encoding for standard strings files. It is possible to create strings files using other property-list formats, including binary property-list formats and XML formats that use the UTF-8 encoding, but doing so is not recommended. For more information about Unicode and its text encodings, go to http://www.unicode.org/ or http://en.wikipedia.org/wiki/Unicode.
}

// See "Localized Metadata" section here: https://docs.fastlane.tools/actions/deliver/
func writeFastlaneAppStoreLocalizedMetadataFile(fileName: String, contents: String, locale: String, path: String) throws {
    let pathForFastlaneMetadataForLocale = "\(path)/fastlane/metadata/\(locale)"
    try FileManager.default.createDirectory(atPath: pathForFastlaneMetadataForLocale, withIntermediateDirectories: true, attributes: nil)
    let descriptionFileURL = URL(fileURLWithPath:"\(pathForFastlaneMetadataForLocale)/\(fileName)",  isDirectory: false)
    try contents.write(to: descriptionFileURL, atomically: true, encoding: .utf8)
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

let locales = Set<String>(Locale.availableIdentifiers)
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
        let contents = try fm.contentsOfDirectory(atPath: "\(path)/Wikipedia/Localizations")
        var pathsForEnglishPlurals: [String] = [] //write english plurals to these paths as placeholders
        var englishPluralDictionary: NSMutableDictionary?
        for filename in contents {
            guard let locale = filename.components(separatedBy: ".").first?.lowercased(), localeIsAvailable(locale) else {
                continue
            }
            guard let twnStrings = NSDictionary(contentsOfFile: "\(path)/Wikipedia/Localizations/\(locale).lproj/Localizable.strings") else {
                continue
            }
            let stringsDict = NSMutableDictionary(capacity: twnStrings.count)
            let strings = NSMutableDictionary(capacity: twnStrings.count)
            for (key, value) in twnStrings {
                guard let twnString = value as? String, let key = key as? String, let enTokens = enTokensByKey[key] else {
                    continue
                }
                let nativeLocalization = twnString.iOSNativeLocalization(tokens: enTokens)
                let nativeLocalizationTokens = nativeLocalization.iOSTokenDictionary
                guard nativeLocalizationTokens == enTokens else {
                    //print("Mismatched tokens in \(locale) for \(key):\n\(enDictionary[key] ?? "")\n\(nativeLocalization)")
                    continue
                }
                if twnString.contains("{{PLURAL:") {
                    let lang = locale.components(separatedBy: "-").first ?? ""
                    let keys = keysByLanguage[lang] ?? defaultKeys
                    stringsDict[key] = twnString.pluralDictionary(with: keys, tokens:enTokens)
                    strings[key] = nativeLocalization
                } else {
                    strings[key] = nativeLocalization
                }
            }
            let stringsFilePath = "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.strings"
            if locale != "en" { // only write the english plurals, skip the main file
                if strings.count > 0 {
                    try writeStrings(fromDictionary: strings, toFile: stringsFilePath)
                    
                    // If we have a localized app store description, write a fastlane "description.txt" to a folder for its locale.
                    if let localizedDescription = strings["app-store-short-description"] as? String {
                        try writeFastlaneAppStoreLocalizedMetadataFile(fileName: "description.txt", contents: localizedDescription, locale: locale, path: path)
                    }
                    
                    // If we have a localized app store subtitle, write a fastlane "subtitle.txt" to a folder for its locale.
                    if let localizedSubtitle = strings["app-store-subtitle"] as? String {
                        try writeFastlaneAppStoreLocalizedMetadataFile(fileName: "subtitle.txt", contents: localizedSubtitle, locale: locale, path: path)
                    }

                    // If we have localized app store release notes, write a fastlane "release_notes.txt" to a folder for its locale.
                    if let localizedReleaseNotes = strings["app-store-release-notes"] as? String {
                        try writeFastlaneAppStoreLocalizedMetadataFile(fileName: "release_notes.txt", contents: localizedReleaseNotes, locale: locale, path: path)
                    }
                    
                    // If we have localized app store keywords, write a fastlane "keywords.txt" to a folder for its locale.
                    if let localizedKeywords = strings["app-store-keywords"] as? String {
                        try writeFastlaneAppStoreLocalizedMetadataFile(fileName: "keywords.txt", contents: localizedKeywords, locale: locale, path: path)
                    }
                    
                } else {
                    do {
                        try fm.removeItem(atPath: stringsFilePath)
                    } catch { }
                }
                
                // If we have a localized app name for "Wikipedia", write a fastlane "name.txt" to a folder for its locale.
                let infoPlistPath = "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/InfoPlist.strings"
                if let infoPlist = NSDictionary(contentsOfFile: infoPlistPath), let localizedAppName = infoPlist["CFBundleDisplayName"] as? String, localizedAppName.count > 0, localizedAppName != "Wikipedia" {
                    try writeFastlaneAppStoreLocalizedMetadataFile(fileName: "name.txt", contents: localizedAppName, locale: locale, path: path)
                }

            } else {
                englishPluralDictionary = stringsDict
            }
            
            let stringsDictFilePath = "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.stringsdict"
            
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
