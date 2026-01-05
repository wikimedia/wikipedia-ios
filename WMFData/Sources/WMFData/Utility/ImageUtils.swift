import Foundation

@objc public final class ImageUtils: NSObject {
    @objc public enum OriginalWidth: Int {
        // Original values * scale of 2 (legacy code)
        case extraSmall = 120
        case small = 240
        case medium = 640
        case large = 1280
        case extraLarge = 2560
        case extraExtraLarge = 3840
    }
    
    @objc public static func listThumbnailWidth() -> Int {
        return OriginalWidth.extraSmall.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func nearbyThumbnailWidth() -> Int {
        return OriginalWidth.small.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func leadImageWidth() -> Int {
        return OriginalWidth.large.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func potdImageWidth() -> Int {
        return OriginalWidth.medium.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func galleryImageWidth() -> Int {
        return OriginalWidth.large.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func articleImageWidth() -> Int {
        return OriginalWidth.medium.rawValue.standardizeToMediaWiki()
    }
    
    @objc public static func standardizeWidthToMediaWiki(_ width: Int) -> Int {
        return width.standardizeToMediaWiki()
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
