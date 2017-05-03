import Foundation

fileprivate var dictionaryRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[{][{])(:?[^{]*)(?:[}][}])", options: [])
    } catch {
        assertionFailure("Localization regex failed to compile")
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
        keyDictionary["NSStringFormatSpecTypeKey"] = "NSStringPluralRuleType"
        keyDictionary["NSStringFormatValueTypeKey"] = "d"
        keyDictionary["other"] = self.replacingCharacters(in: range, with: other).replacingOccurrences(of: token, with: "%d")
        
        if countOfComponents > 2 {
            keyDictionary["one"] = self.replacingCharacters(in: range, with: components[1]).replacingOccurrences(of: token, with: "%d")
        }
        
        if countOfComponents > 3 {
            keyDictionary["few"] = self.replacingCharacters(in: range, with: components[2]).replacingOccurrences(of: token, with: "%d")
        }
        
        let key = "v0"
        mutableDictionary[key] = keyDictionary
        let replacement = "%#@\(key)@"
        mutableDictionary["NSStringLocalizedFormatKey"] = replacement
        return mutableDictionary
    }
}

let fm = FileManager.default

do {
	let contents = try fm.contentsOfDirectory(atPath: "Wikipedia/Localizations")
	for filename in contents {
		guard let locale = filename.components(separatedBy: ".").first else {
			continue
		}
		guard let twnStrings = NSDictionary(contentsOfFile: "Wikipedia/Localizations/\(locale).lproj/Localizable.strings") else {
		    continue
		}
		let stringsDict = NSMutableDictionary(capacity: twnStrings.count)
		for (key, value) in twnStrings {
		    guard let twnString = value as? String else {
		        continue
		    }
		    if twnString.contains("{{PLURAL:") {
		        stringsDict[key] = twnString.pluralDictionary
		    }
		}
		guard stringsDict.count > 0 else {
			do {
				try fm.removeItem(atPath: "Wikipedia/Localizations/\(locale).lproj/Localizable.stringsdict")
			} catch { }
			continue
		}
		stringsDict.write(toFile: "Wikipedia/Localizations/\(locale).lproj/Localizable.stringsdict", atomically: true)
	}
	
} catch let error {
	
}

