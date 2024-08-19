// Wrapper for JS sharedlib for the iOS and Android apps
// Experimental as of 2024-07-29

import Foundation
import JavaScriptCore

public struct WMFMissingAltTextLink {
    public init(text: String, file: String, offset: Int, length: Int) {
        self.text = text
        self.file = file
        self.offset = offset
        self.length = length
    }
    
    public var text: String
    public var file: String
    public var offset: Int
    public var length: Int
}

public enum WMFAltTextDetectorError: Error {
    case failureDeterminingLibraryPath
    case missingRootLevelObject
}

final class WMFAltTextDetector {
    var context: JSContext

    public init() throws {
        context = JSContext()

        let altPath = Bundle.module.path(forResource: "alt-text", ofType: "js")

        guard let altPath else {
            throw WMFAltTextDetectorError.failureDeterminingLibraryPath
        }
        let alt = try String(contentsOfFile: altPath)

        context.evaluateScript(alt)
    }

    func missingAltTextLinks(text: String, language: String, targetNamespaces: [String], targetAltParams: [String]) throws -> [WMFMissingAltTextLink] {
        
        guard let f = context.globalObject.objectForKeyedSubscript("missingAltTextLinks") else {
            throw WMFAltTextDetectorError.missingRootLevelObject
        }
        
        let ret = f.call(withArguments:[text, language, targetNamespaces, targetAltParams])
        var arr = [WMFMissingAltTextLink]()
        let len = Int(ret?.objectForKeyedSubscript("length").toInt32() ?? 0)
        for i in 0..<len {
            guard let link = ret?.objectAtIndexedSubscript(i),
            let text = link.objectForKeyedSubscript("text")?.toString(),
            let file = link.objectForKeyedSubscript("file")?.toString(),
            let offset = link.objectForKeyedSubscript("offset")?.toInt32(),
                  let length = link.objectForKeyedSubscript("length")?.toInt32() else {
                continue
            }
            arr.append(WMFMissingAltTextLink(
                text: text,
                file: file,
                offset: Int(offset),
                length: Int(length)
            ))
        }
        return arr
    }
}

public extension WMFWikitextUtils {

    /// Detect image links with missing alt text
    /// - Parameters:
    ///   - text: Text to evaluate
    ///   - language: Language code
    ///   - targetNamespaces: Namespaces to target ("File", "Image")
    ///   - targetAltParams: Alt parameter names to target ("alt", "alternativtext")
    /// - Returns: Array of MissingAltTextLinks representing file links missing alt text.
    static func missingAltTextLinks(text: String, language: String, targetNamespaces: [String], targetAltParams: [String]) throws -> [WMFMissingAltTextLink] {
        let altTextDetector = try WMFAltTextDetector()
        return try altTextDetector.missingAltTextLinks(text: text, language: language, targetNamespaces: targetNamespaces, targetAltParams: targetAltParams)
    }
    
    // MARK: - Insert Alt text Into Image Wikitext
    
    @available(iOS 16.0, *)
    /// Given full article wikitext, image wikitext within full article wikitext, caption within image wikitext, and new alt text, this method inserts the alt text in the correct spot and returns the new full article wikitext for posting.
    /// - Parameters:
    ///   - altText: Alt text to insert into imageWikitext
    ///   - caption: Caption that resides in the image wikitext
    ///   - imageWikitext: image wikitext ([[File: Test.jpg | thumb | Caption text.]])
    ///   - fullArticleWikitextWithImage: Full article wikitext, which must already contain imageWikitext.
    /// - Returns: Full article wikitext with alt text inserted into the correct spot within imageWikitext
    static func insertAltTextIntoImageWikitext(altText: String, caption: String?, imageWikitext: String, fullArticleWikitextWithImage: String) -> String {
        var finalImageWikitext = imageWikitext
        if let caption,
           let captionRegex = try? Regex("\\|\\s*\(caption)\\s*]]$"),
           let range = imageWikitext.ranges(of: captionRegex).first {
            finalImageWikitext.replaceSubrange(range, with: "| \(altText) | \(caption)]]")
        } else if let finalLinkRegex = try? Regex("]]$"),
                  let range = imageWikitext.ranges(of: finalLinkRegex).first {
            finalImageWikitext.replaceSubrange(range, with: "| \(altText)]]")
        }
        
        var finalFullArticleWikitextWithImage = fullArticleWikitextWithImage
        if let range = finalFullArticleWikitextWithImage.range(of: imageWikitext) {
            finalFullArticleWikitextWithImage.replaceSubrange(range, with: finalImageWikitext)
        }
        
        return finalFullArticleWikitextWithImage
    }
}
