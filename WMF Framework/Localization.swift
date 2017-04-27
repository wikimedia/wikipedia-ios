import Foundation

fileprivate var dictionaryRegex: NSRegularExpression? = {
    do {
        return try NSRegularExpression(pattern: "(?:[{][{])(:?[^{]*)(?:[}][}])", options: [])
    } catch {
        assertionFailure("Localization regex failed to compile")
    }
    return nil
}()

fileprivate var reverseDecimalFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    return formatter
}()


public func localizedString(withFormat format: String, replacements: [String]) -> String? {
    guard let dictionaryRegex = dictionaryRegex else {
        return nil
    }
    let mutableFormat = NSMutableString(string: format)
    var offset = 0
    dictionaryRegex.enumerateMatches(in: format, options: [], range: NSRange(location: 0, length: mutableFormat.length), using: { (result, flags, stop) in
        guard let result = result else {
            return
        }
        
        let contents = dictionaryRegex.replacementString(for: result, in: mutableFormat as String, offset: offset, template: "$1")
        let range = NSRange(location: result.range.location + offset, length: result.range.length)
        let replaceMatchWith = { (string: String) in
            offset += (string as NSString).length - result.range.length
            mutableFormat.replaceCharacters(in: range, with: string)
        }
        
        let components = contents.components(separatedBy: "|")
        guard components.count > 1 else {
            replaceMatchWith("")
            return
        }

        let firstComponent = components[0]
        guard firstComponent.hasPrefix("PLURAL:$") else {
            replaceMatchWith(components[1])
            return
        }

        guard let i = Int(firstComponent.substring(from: firstComponent.index(firstComponent.startIndex, offsetBy: 8))), i > 0, i <= replacements.count else {
            replaceMatchWith(components[1])
            return
        }
        
        let replacement = replacements[i - 1]
        guard let replacementDouble = reverseDecimalFormatter.number(from: replacement)?.doubleValue else {
            replaceMatchWith(components[1])
            return
        }
        
        let index = replacementDouble == 1 ? 1 : 2
        guard index < components.count else {
            replaceMatchWith(components[1])
            return
        }
        
        replaceMatchWith(components[index])
    })
    for (index, replacement) in replacements.enumerated() {
        mutableFormat.replaceOccurrences(of: "$\(index + 1)", with: replacement, options: [], range: NSRange(location: 0, length: mutableFormat.length))
    }
    return mutableFormat as String
}

public func localizedString(_ key: String, _ replacements: String...) -> String? {
    let formatString = localizedStringForKeyFallingBackOnEnglish(key)
    return localizedString(withFormat: formatString, replacements: replacements)
}

public func localizedString(withFormat format: String, _ replacements: String...) -> String? {
    return localizedString(withFormat: format, replacements: replacements)
}
