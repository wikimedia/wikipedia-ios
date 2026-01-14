import Foundation

@objc public final class ImageUtils: NSObject {
    // Note these were the original legacy thumbnail request sizes. All code requesting thumbnails should now flow  through the `standardizeToMediaWiki` helper method to reorient to backend expectations.
    @objc public enum LegacyWidth: Int {
        // Original values * scale of 2 (legacy code)
        case extraSmall = 120
        case small = 240
        case medium = 640
        case large = 1280
        case extraLarge = 2560
        case extraExtraLarge = 3840
    }
    
    @objc public static func listThumbnailWidth() -> Int {
        return LegacyWidth.extraSmall.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func nearbyThumbnailWidth() -> Int {
        return LegacyWidth.small.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func leadImageWidth() -> Int {
        return LegacyWidth.large.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func potdImageWidth() -> Int {
        return LegacyWidth.medium.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func galleryImageWidth() -> Int {
        return LegacyWidth.large.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func articleImageWidth() -> Int {
        return LegacyWidth.medium.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func standardizeWidthToMediaWiki(_ width: Int) -> Int {
        return width.standardizeToMediaWiki()
    }

    /**
     Parse the file page title from an image's source URL and then unescape and normalize it.
     The returned string will be unescaped and precomposed using canonical mapping.
     
     - Parameter sourceURL: The source URL for an image, i.e. the "src" attribute of the `<img>` element.
     - Returns: The unescaped and normalized image name, or nil if parsing fails.
     - Note: This will remove any extra path extensions in sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
     - Warning: This method does regex parsing, be sure to cache the result if possible.
     */
    public func parseUnescapedUnderscoresToSpacesImageName(from url: URL) -> String? {
        return parseUnescapedUnderscoresToSpacesImageName(from: url.absoluteString)
    }

    /**
     Parse the file page title from an image's source URL and then unescape and normalize it.
     The returned string will be unescaped and precomposed using canonical mapping.
     
     - Parameter sourceURLString: The source URL string for an image.
     - Returns: The unescaped and normalized image name, or nil if parsing fails.
     - Note: This will remove any extra path extensions in sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
     - Warning: This method does regex parsing, be sure to cache the result if possible.
     */
    public func parseUnescapedUnderscoresToSpacesImageName(from urlString: String) -> String? {
        guard let imageName = parseImageName(from: urlString) else {
            return nil
        }
        return imageName.unescapedUnderscoresToSpaces
    }

    /**
     Parse the file page title from an image's source URL.
     
     - Parameter sourceURL: The source URL for an image, i.e. the "src" attribute of the `<img>` element.
     - Returns: The image name, or nil if parsing fails.
     - Note: This will remove any extra path extensions in sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
     - Warning: This method does regex parsing, be sure to cache the result if possible.
     */
    public func parseImageName(from url: URL) -> String? {
        return parseImageName(from: url.absoluteString)
    }

    /**
     Parse the file page title from an image's source URL.
     
     - Parameter sourceURLString: The source URL string for an image.
     - Returns: The image name, or nil if parsing fails.
     - Note: This will remove any extra path extensions in sourceURL (e.g. ".../10px-foo.svg.png" to "foo.svg").
     - Warning: This method does regex parsing, be sure to cache the result if possible.
     */
    public func parseImageName(from urlString: String?) -> String? {
        guard let urlString else {
            return nil
        }
        
        let pathComponents = urlString.components(separatedBy: "/")
        guard pathComponents.count >= 2 else {
            debugPrint("Unable to parse source URL with too few path components: \(pathComponents)")
            return nil
        }
        
        if !isThumbURLString(urlString) {
            return (urlString as NSString).lastPathComponent
        } else {
            return pathComponents[pathComponents.count - 2]
        }
    }

    /**
     Parse the size prefix from an image's source URL.
     
     - Parameter sourceURL: The source URL for an image.
     - Returns: The size prefix as an integer, or nil if not found.
     */
    public func parseSizePrefix(from url: URL) -> Int? {
        return parseSizePrefix(from: url.absoluteString)
    }

    /**
     Parse the size prefix from an image's source URL.
     
     - Parameter sourceURLString: The source URL string for an image.
     - Returns: The size prefix as an integer, or nil if not found.
     */
    public func parseSizePrefix(from urlString: String?) -> Int? {
        guard let urlString else {
            return nil
        }
        
        guard isThumbURLString(urlString) else {
            return nil
        }
        
        let fileName = (urlString as NSString).lastPathComponent
        guard !fileName.isEmpty else {
            return nil
        }
        
        guard let pxRange = fileName.range(of: "px-") else {
            return nil
        }
        
        let stringBeforePx = String(fileName[..<pxRange.lowerBound])
        
        let result: Int
        if let lastDashRange = stringBeforePx.range(of: "-", options: .backwards) {
            // stringBeforePx is "page1-240" for the following:
            // upload.wikimedia.org/wikipedia/commons/thumb/6/65/A_Fish_and_a_Gift.pdf/page1-240px-A_Fish_and_a_Gift.pdf.jpg
            let stringAfterDash = String(stringBeforePx[stringBeforePx.index(after: lastDashRange.lowerBound)...])
            result = Int(stringAfterDash) ?? 0
        } else {
            // stringBeforePx is "200" for the following:
            // upload.wikimedia.org/wikipedia/commons/thumb/4/41/200px-Potato.jpg/
            result = Int(stringBeforePx) ?? 0
        }
        
        return result == 0 ? nil : result
    }

    /**
     Get the original (non-thumbnail) image URL from a source URL.
     
     - Parameter urlString: The source URL string.
     - Returns: The original image URL string.
     */
    public func originalImageURLString(from urlString: String) -> String {
        var result = urlString
        if result.contains("/thumb/") {
            result = (result as NSString).deletingLastPathComponent
            result = result.replacingOccurrences(of: "/thumb/", with: "/")
        }
        return result
    }

    /**
     Change the size prefix of an image source URL.
     
     - Parameters:
       - sourceURL: A commons or lang wiki image url with or without a size prefix (the size prefix is the "XXXpx-" part of "https://upload.wikimedia.org/wikipedia/commonsOrLangCode/thumb/.../Filename.jpg/XXXpx-Filename.jpg")
       - newSizePrefix: A new size prefix number. If the sourceURL had a prefix number, this number will replace it. If it did not have a size prefix it will be added as will the "/thumb/" portion.
     - Returns: An image url in the form of "https://upload.wikimedia.org/wikipedia/commonsOrLangCode/thumb/.../Filename.jpg/XXXpx-Filename.jpg" where the image size prefix has been changed to newSizePrefix
     */
    public func changeImageSourceURLSizePrefix(_ urlString: String, newSizePrefix: Int) -> String {
        var adjustedPrefix = newSizePrefix
        if adjustedPrefix < 1 {
            adjustedPrefix = 1
        }
        
        let wikipediaString = "/wikipedia/"
        guard let wikipediaRange = urlString.range(of: wikipediaString) else {
            return urlString
        }
        
        guard !urlString.isEmpty else {
            return urlString
        }
        
        let urlAfterWikipedia = String(urlString[wikipediaRange.upperBound...])
        guard let slashRange = urlAfterWikipedia.range(of: "/") else {
            return urlString
        }
        
        let site = String(urlAfterWikipedia[..<slashRange.lowerBound])
        guard !site.isEmpty else {
            return urlString
        }
        
        let lastPathComponent = (urlString as NSString).lastPathComponent
        
        if parseSizePrefix(from: urlString) == nil {
            // No existing size prefix - add one
            var sizeVariantLastPathComponent = "\(adjustedPrefix)px-\(lastPathComponent)"
            
            let lowerCasePathExtension = (urlString as NSString).pathExtension.lowercased()
            if lowerCasePathExtension == "pdf" {
                sizeVariantLastPathComponent = "page1-\(sizeVariantLastPathComponent).jpg"
            } else if lowerCasePathExtension == "tif" || lowerCasePathExtension == "tiff" {
                sizeVariantLastPathComponent = "lossy-page1-\(sizeVariantLastPathComponent).jpg"
            } else if lowerCasePathExtension == "svg" {
                sizeVariantLastPathComponent = "\(sizeVariantLastPathComponent).png"
            }
            
            let urlWithSizeVariantLastPathComponent = "\(urlString)/\(sizeVariantLastPathComponent)"
            
            let urlWithThumbPath = urlWithSizeVariantLastPathComponent.replacingOccurrences(
                of: "\(wikipediaString)\(site)/",
                with: "\(wikipediaString)\(site)/thumb/"
            )
            
            return urlWithThumbPath
        } else {
            // Existing size prefix - replace it
            let lastPathComponentRange = (urlString as NSString).range(of: lastPathComponent, options: .backwards)
            let nsRange = NSRange(location: lastPathComponentRange.location, length: lastPathComponent.count)
            
            return imageURLParsingRegex.stringByReplacingMatches(
                in: urlString,
                options: .anchored,
                range: nsRange,
                withTemplate: "$1$2\(adjustedPrefix)px-$3"
            )
        }
    }
    
    // MARK: - Private Helpers

    private let imageURLParsingRegex: NSRegularExpression = {
        // TODO: try to read serialized regex from disk to prevent needless pattern compilation on next app run
        do {
            return try NSRegularExpression(pattern: "^(lossy-|lossless-)?(page\\d+-)?\\d+px-(.*)", options: [])
        } catch {
            fatalError("Failed to compile regex pattern: \(error)")
        }
    }()

    private func isThumbURLString(_ urlString: String) -> Bool {
        return urlString.contains("/thumb/")
    }
}

fileprivate extension Int {
    func standardizeToMediaWiki() -> Int {
        let standardMediaWikiWidths: [Int] = [
            20,
            40,
            60,
            120,
            250,
            330,
            500,
            960
        ]
        
        var chosenStandardWidth: Int = 20
        for mwWidth in standardMediaWikiWidths {
            chosenStandardWidth = mwWidth
            
            if self <= mwWidth {
                break
            }
        }
        
        return chosenStandardWidth
    }
}
