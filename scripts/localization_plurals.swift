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
        let mutableSelf = NSMutableString(string: self)
        var offset = 0
        var i = 0
        dictionaryRegex.enumerateMatches(in: self, options: [], range: fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            
            let contents = dictionaryRegex.replacementString(for: result, in: mutableSelf as String, offset: offset, template: "$1")
            let range = NSRange(location: result.range.location + offset, length: result.range.length)
            let components = contents.components(separatedBy: "|")
            let replaceMatchWith = { (string: String) in
                offset += string.characters.count - result.range.length
                mutableSelf.replaceCharacters(in: range, with: string)
            }
            let countOfComponents = components.count
            guard countOfComponents > 1 else {
                replaceMatchWith("")
                return
            }
            
            let firstComponent = components[0]
            let other = components[countOfComponents - 1]
            guard firstComponent.hasPrefix("PLURAL:") else {
                replaceMatchWith(other)
                return
            }
            
            let token = firstComponent.substring(from: firstComponent.index(firstComponent.startIndex, offsetBy: 7))
            guard token.characters.count == 2 else {
                replaceMatchWith(other)
                return
            }
            mutableSelf.replaceOccurrences(of: token, with: "%d", options: [], range: NSRange(location: 0, length: mutableSelf.length))
            let keyDictionary = NSMutableDictionary(capacity: 5)
            keyDictionary["NSStringFormatSpecTypeKey"] = "NSStringPluralRuleType"
            keyDictionary["NSStringFormatValueTypeKey"] = "d"
            keyDictionary["other"] = other.replacingOccurrences(of: token, with: "%d")
            
            if countOfComponents > 2 {
                keyDictionary["one"] = components[1].replacingOccurrences(of: token, with: "%d")
            }
            
            if countOfComponents > 3 {
                keyDictionary["few"] = components[2].replacingOccurrences(of: token, with: "%d")
            }
            
            let key = "v\(i)"
            i += 1
            mutableDictionary[key] = keyDictionary
            
            let replacement = "%#@\(key)@"
            replaceMatchWith(replacement)
        }
        mutableDictionary["NSStringLocalizedFormatKey"] = mutableSelf
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

