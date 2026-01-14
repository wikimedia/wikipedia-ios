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
            960,
            1280,
            1920,
            3840 
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
