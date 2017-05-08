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

extension String {
    var fullRange: NSRange {
        return NSRange(location: 0, length: (self as NSString).length)
    }
    var escapedString: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"").replacingOccurrences(of: "\n", with: "\\n")
    }
    func pluralDictionary(with keys: [String]) -> NSDictionary? {
		//https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/StringsdictFileFormat/StringsdictFileFormat.html#//apple_ref/doc/uid/10000171i-CH16-SW1
        guard let dictionaryRegex = dictionaryRegex else {
            return nil
        }
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
        
        let token = firstComponent.substring(from: firstComponent.index(firstComponent.startIndex, offsetBy: 7))
        guard (token as NSString).length == 2 else {
            return nil
        }
        
        let other = components[countOfComponents - 1]
        let lower = index(startIndex, offsetBy: result.range.location)
        let upper = index(lower, offsetBy: result.range.length)
        let range = lower..<upper
        
        let keyDictionary = NSMutableDictionary(capacity: 5)
        let formatValueType = "d"
        keyDictionary["NSStringFormatSpecTypeKey"] = "NSStringPluralRuleType"
        keyDictionary["NSStringFormatValueTypeKey"] = formatValueType
        let newToken = "%1$\(formatValueType)"
        keyDictionary["other"] = self.replacingCharacters(in: range, with: other).replacingOccurrences(of: token, with: newToken)

		var keyIndex = 0
		guard let countPrefixRegex = countPrefixRegex else {
		    abort()
		}
		for component in components[1..<(countOfComponents - 1)]{
		    var keyForComponent: String?
			var actualComponent: String? = component
		    if let match = countPrefixRegex.firstMatch(in: component, options: [], range: component.fullRange) {
		        let numberString = countPrefixRegex.replacementString(for: match, in: component, offset: 0, template: "$1")
		        if numberString == "0" {
		            actualComponent = (component as NSString).substring(from: match.range.length) as String?
		            keyForComponent = "zero"
		        }
        
		    } else {
		    	if keyIndex < keys.count {
		    		keyForComponent = keys[keyIndex]
					keyIndex += 1
		    	}
		    }
			
			guard let keyToInsert = keyForComponent, let componentToInsert = actualComponent else {
				continue
			}
			
			keyDictionary[keyToInsert] = self.replacingCharacters(in: range, with: componentToInsert).replacingOccurrences(of: token, with: newToken)
			
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
    
    var iOSNativeLocalization: String {
        guard let tokenRegex = twnTokenRegex else {
            return ""
        }
        return self.replacingMatches(fromRegex: tokenRegex, withFormat: "%%%@$@")
    }
    
    var twnNativeLocalization: String {
        guard let tokenRegex = iOSTokenRegex else {
            return ""
        }
        return self.replacingMatches(fromRegex: tokenRegex, withFormat: "$%@")
    }
}

func writeStrings(fromDictionary dictionary: [String: String], toFile: String, escaped: Bool) throws {
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

	var twnQQQ = [String: String]()
	var twnEN = [String: String]()

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
	               currentKey = quotesRemoved.substring(to: range.lowerBound)
	           }
	       }
	       if let key = currentKey, let comment =  currentComment {
	           commentsByKey[key] = comment
	       }
	   }

	   for (key, comment) in commentsByKey {
	       twnQQQ[key] = comment.twnNativeLocalization
	   }
	   try writeStrings(fromDictionary: twnQQQ, toFile: twnQQQPath, escaped: false)

	   for (key, value) in iOSEN {
	       guard let value = value as? String, let key = key as? String  else {
	           continue
	       }
	       twnEN[key] = value.twnNativeLocalization
	   }
	   try writeStrings(fromDictionary: twnEN, toFile: twnENPath, escaped: true)
	} catch let error {
	   print("Error exporting localizations: \(error)")
       abort()
	}
}


func importLocalizationsFromTWN(_ path: String) {
	let enPath = "\(path)/Wikipedia/iOS Native Localizations/en.lproj/Localizable.strings"
	guard let enDictionary = NSDictionary(contentsOfFile: enPath) as? [String:String] else {
	       print("Unable to read \(enPath)")
	       abort()
	}
	
	let fm = FileManager.default

	do {
		let keysByLanguage = ["pl": ["one", "few"], "sr": ["one", "few", "many"]]
        let languagesToSkip = ["en", "azb", "be-tarask", "bgn", "cnh", "gom-latn", "ku-latn", "nah", "olo", "wuu", "xmf", "qqq"]
		let defaultKeys = ["one"]
	   let contents = try fm.contentsOfDirectory(atPath: "\(path)/Wikipedia/Localizations")
	   for filename in contents {
	       guard let locale = filename.components(separatedBy: ".").first?.lowercased(), !languagesToSkip.contains(locale) else {
	           continue
	       }
	       guard let twnStrings = NSDictionary(contentsOfFile: "\(path)/Wikipedia/Localizations/\(locale).lproj/Localizable.strings") else {
	           continue
	       }
	       let stringsDict = NSMutableDictionary(capacity: twnStrings.count)
	       let strings = NSMutableDictionary(capacity: twnStrings.count)
	       for (key, value) in twnStrings {
	           guard let twnString = value as? String, let key = key as? String, enDictionary[key] != nil else {
	               continue
	           }
	           if twnString.contains("{{PLURAL:") {
				   let lang = locale.components(separatedBy: "-").first ?? ""
				   let keys = keysByLanguage[lang] ?? defaultKeys
	               stringsDict[key] = twnString.pluralDictionary(with: keys)
	           } else {
	               strings[key] = twnString.iOSNativeLocalization
	           }
	       }

	       try writeStrings(fromDictionary: strings as! [String: String], toFile: "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.strings", escaped: true)
	       guard stringsDict.count > 0 else {
	           do {
	               try fm.removeItem(atPath: "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.stringsdict")
	           } catch { }
	           continue
	       }
	       stringsDict.write(toFile: "\(path)/Wikipedia/iOS Native Localizations/\(locale).lproj/Localizable.stringsdict", atomically: true)
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
// 			let path = codePath + "/" + filename
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
// 			try mutableString.write(toFile: path, atomically: true, encoding: String.Encoding.utf8.rawValue)
//      } catch { }
// }
