import Foundation

@objc public final class ImageUtils: NSObject {
    
    @objc public enum ImageWidth: Int {
        case w20 = 20
        case w40 = 40
        case w60 = 60
        case w120 = 120
        case w250 = 250
        case w330 = 330
        case w500 = 500
        case w960 = 960
        case w1280 = 1280
        case w1920 = 1920
        case w3840 = 3840
    }
    
    @objc public static func listThumbnailWidth() -> Int {
        return ImageWidth.w120.rawValue
    }
    
    @objc public static func nearbyThumbnailWidth() -> Int {
        return ImageWidth.w250.rawValue
    }
    
    @objc public static func leadImageWidth() -> Int {
        return ImageWidth.w1280.rawValue
    }
    
    @objc public static func potdImageWidth() -> Int {
        return ImageWidth.w500.rawValue
    }
    
    @objc public static func galleryImageWidth() -> Int {
        return ImageWidth.w1280.rawValue
    }
    
    @objc public static func articleImageWidth() -> Int {
        return ImageWidth.w500.rawValue
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
