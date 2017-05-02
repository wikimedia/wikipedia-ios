import Foundation

fileprivate var dictionaryRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[{][{])(:?[^{]*)(?:[}][}])", options: [])
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
        return try NSRegularExpression(pattern: "(?:[%])(:?[0-9]+)(?:[$][@dDuUxXoOfeEgGcCsSpaAF])", options: [])
    } catch {
        assertionFailure("Localization token regex failed to compile")
    }
    return nil
}()

extension String {
    var pluralDictionary: NSDictionary? {
        guard let dictionaryRegex = dictionaryRegex else {
            return nil
        }
        let fullRange = NSRange(location: 0, length: self.characters.count)
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
        let other = components[countOfComponents - 1]
        guard firstComponent.hasPrefix("PLURAL:") else {
            return nil
        }
        
        let token = firstComponent.substring(from: firstComponent.index(firstComponent.startIndex, offsetBy: 7))
        guard token.characters.count == 2 else {
            return nil
        }
        
        let lower = index(startIndex, offsetBy: result.range.location)
        let upper = index(lower, offsetBy: result.range.length)
        let range = lower..<upper
        
        let keyDictionary = NSMutableDictionary(capacity: 5)
		let formatValueType = "d"
        keyDictionary["NSStringFormatSpecTypeKey"] = "NSStringPluralRuleType"
        keyDictionary["NSStringFormatValueTypeKey"] = formatValueType
		let newToken = "%1$\(formatValueType)"
        keyDictionary["other"] = self.replacingCharacters(in: range, with: other).replacingOccurrences(of: token, with: newToken)
        
        if countOfComponents > 2 {
            keyDictionary["one"] = self.replacingCharacters(in: range, with: components[1]).replacingOccurrences(of: token, with: newToken)
        }
        
        if countOfComponents > 3 {
            keyDictionary["few"] = self.replacingCharacters(in: range, with: components[2]).replacingOccurrences(of: token, with: newToken)
        }
        
        let key = "v0"
        mutableDictionary[key] = keyDictionary
        let replacement = "%#@\(key)@"
        mutableDictionary["NSStringLocalizedFormatKey"] = replacement
        return mutableDictionary
    }
    
    var iOSNativeLocalization: String {
        guard let tokenRegex = twnTokenRegex else {
            return ""
        }
        var nativeLocalization = self as NSString
        var offset = 0
        let fullRange = NSRange(location: 0, length: nativeLocalization.length)
        tokenRegex.enumerateMatches(in: nativeLocalization as String, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            let token = tokenRegex.replacementString(for: result, in: nativeLocalization as String, offset: offset, template: "$1")
            let replacement = "%\(token)$@"
            nativeLocalization = nativeLocalization.replacingCharacters(in: NSRange(location: result.range.location + offset, length: result.range.length), with: replacement) as NSString
            offset += replacement.characters.count - result.range.length
        }
        return nativeLocalization as String
    }
    
    var twnNativeLocalization: String {
        guard let tokenRegex = iOSTokenRegex else {
            return ""
        }
        var nativeLocalization = self as NSString
        var offset = 0
        let fullRange = NSRange(location: 0, length: nativeLocalization.length)
        tokenRegex.enumerateMatches(in: nativeLocalization as String, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            let token = tokenRegex.replacementString(for: result, in: nativeLocalization as String, offset: offset, template: "$1")
            let replacement = "$\(token)"
            nativeLocalization = nativeLocalization.replacingCharacters(in: NSRange(location: result.range.location + offset, length: result.range.length), with: replacement) as NSString
            offset += replacement.characters.count - result.range.length
        }
        return nativeLocalization as String
    }
}

func writeStrings(fromDictionary dictionary: [String: String], toFile: String) throws {
    var output = ""
	let sortedDictionary = dictionary.sorted(by: { (kv1, kv2) -> Bool in
    	return kv1.key < kv2.key
	})
    for (key, value) in sortedDictionary {
        output.append("\"\(key)\" = \"\(value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n"))\";\n")
    }

	try output.write(toFile: toFile, atomically: true, encoding: .utf8)
}

let basePath = "Wikipedia/iOS Native Localizations/Base.lproj/Localizable.strings"
let qqqPath = "Wikipedia/Localizations/qqq.lproj/Localizable.strings"
let enPath = "Wikipedia/Localizations/en.lproj/Localizable.strings"

guard let baseDictionary = NSDictionary(contentsOfFile: basePath),
let qqqDictionary = NSMutableDictionary(contentsOfFile: qqqPath),
let enDictionary = NSMutableDictionary(contentsOfFile: enPath) else {
	abort()
}


do {
    let commentSet = CharacterSet(charactersIn: "/* ")
    let quoteSet = CharacterSet(charactersIn: "\"")
    let string = try String(contentsOfFile: basePath)
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
                currentKey = quotesRemoved.substring(to: range.lowerBound)
            }
        }
        if let key = currentKey, let comment =  currentComment {
            commentsByKey[key] = comment
        }
    }

    for (key, comment) in commentsByKey {
        qqqDictionary[key] = comment
    }
    try writeStrings(fromDictionary: qqqDictionary as! [String: String], toFile: qqqPath)
	
	for (key, value) in baseDictionary {
		guard let value = value as? String else {
			continue
		}
    	enDictionary[key] = value.twnNativeLocalization
    }
    try writeStrings(fromDictionary: enDictionary as! [String: String], toFile: enPath)
	
	
	for (key, comment) in qqqDictionary {
		
	}
	

} catch let error {
    print("error: \(error)")
}


let fm = FileManager.default

do {
    let contents = try fm.contentsOfDirectory(atPath: "Wikipedia/Localizations")
    for filename in contents {
		//print("parsing \(filename)")
        guard let locale = filename.components(separatedBy: ".").first else {
            continue
        }
        guard let twnStrings = NSDictionary(contentsOfFile: "Wikipedia/Localizations/\(locale).lproj/Localizable.strings") else {
            continue
        }
        let stringsDict = NSMutableDictionary(capacity: twnStrings.count)
        let strings = NSMutableDictionary(capacity: twnStrings.count)
        for (key, value) in twnStrings {
            guard let twnString = value as? String else {
                continue
            }
            if twnString.contains("{{PLURAL:") {
                stringsDict[key] = twnString.pluralDictionary
            } else {
                strings[key] = twnString.iOSNativeLocalization
            }
        }
		
		try writeStrings(fromDictionary: strings as! [String: String], toFile: "Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.strings")
        guard stringsDict.count > 0 else {
            do {
                try fm.removeItem(atPath: "Wikipedia/Localizations/\(locale).lproj/Localizable.stringsdict")
            } catch { }
            continue
        }
        stringsDict.write(toFile: "Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.stringsdict", atomically: true)
    }
    
} catch let error {
    
}


