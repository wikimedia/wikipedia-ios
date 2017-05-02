import Foundation

func writeStrings(fromDictionary dictionary: [String: String], toFile: String) throws {
    var output = ""
    for (key, value) in dictionary {
        output.append("\"\(key)\" = \"\(value)\";\n")
    }

	try output.write(toFile: toFile, atomically: true, encoding: .utf8)
}

let basePath = "Wikipedia/Localizations/Base.lproj/Localizable.strings"
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
    	enDictionary[key] = value
    }
    try writeStrings(fromDictionary: enDictionary as! [String: String], toFile: enPath)
	

} catch let error {
    print("error: \(error)")
}

