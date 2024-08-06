// Wrapper for JS sharedlib for the iOS and Android apps
// Experimental as of 2024-07-29

import Foundation
import JavaScriptCore

public struct MissingAltTextLink {
    public var text: String
    public var file: String
    public var offset: Int
    public var length: Int
}

public class AltText {
    var context: JSContext

    public init() throws {
        context = JSContext()

        let altPath = Bundle.main.path(forResource: "alt-text", ofType: "js", inDirectory: "sharedlib")!

        let alt = try String(contentsOfFile: altPath)

        context.evaluateScript(alt)
    }

    public func missingAltTextLinks(text: String, language: String) throws -> [MissingAltTextLink] {
        let f = context.globalObject.objectForKeyedSubscript("missingAltTextLinks")!
        let ret = f.call(withArguments:[text, language])
        var arr = [MissingAltTextLink]()
        let len = Int(ret?.objectForKeyedSubscript("length").toInt32() ?? 0)
        for i in 0..<len {
            let link = ret?.objectAtIndexedSubscript(i)
            let text = link?.objectForKeyedSubscript("text")?.toString()
            let file = link?.objectForKeyedSubscript("file")?.toString()
            let offset = link?.objectForKeyedSubscript("offset")?.toInt32()
            let length = link?.objectForKeyedSubscript("length")?.toInt32()
            arr.append(MissingAltTextLink(
                text: text!,
                file: file!,
                offset: Int(offset!),
                length: Int(length!)
            ))
        }
        return arr
    }
}
