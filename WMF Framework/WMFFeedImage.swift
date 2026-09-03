import Foundation
import WMFData

/// The picture of the day for the Explore feed.
///
/// This class is a temporary bridge. WMFData decodes the picture into a `WMFFeedImageNew` struct.
/// The Explore feed archives this class into Core Data with NSSecureCoding. The class name and the
/// coding keys are the same as the old Mantle model, so archives from earlier app versions still decode.
/// Remove this class when the Explore feed is removed.
@objc(WMFFeedImage)
@objcMembers
public final class WMFFeedImage: NSObject, NSSecureCoding {

    public let canonicalPageTitle: String
    public let imageDescription: String
    public let imageDescriptionIsRTL: Bool
    public private(set) var imageThumbURL: URL
    public private(set) var imageURL: URL
    public let imageWidth: NSNumber?
    public let imageHeight: NSNumber?

    public init(canonicalPageTitle: String, imageDescription: String, imageDescriptionIsRTL: Bool, imageThumbURL: URL, imageURL: URL, imageWidth: NSNumber?, imageHeight: NSNumber?) {
        self.canonicalPageTitle = canonicalPageTitle
        self.imageDescription = imageDescription
        self.imageDescriptionIsRTL = imageDescriptionIsRTL
        self.imageThumbURL = imageThumbURL
        self.imageURL = imageURL
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        super.init()
    }

    /// Create the bridge object from the WMFData model. The initializer fails when the title or the image URL is missing.
    public convenience init?(image: WMFFeedImageNew, languageVariantCode: String?) {
        guard let title = image.title,
              let imageURLString = image.image?.source,
              let imageURL = URL(string: imageURLString) else {
            return nil
        }

        // Request the largest standard thumbnail so that the image looks sharp on every screen.
        var thumbnailURL = imageURL
        if let thumbnailString = image.thumbnail?.source {
            var adjusted = thumbnailString
            if WMFParseSizePrefixFromSourceURL(thumbnailString) < ImageUtils.ImageWidth.w3840.rawValue,
               let resized = WMFChangeImageSourceURLSizePrefix(thumbnailString, ImageUtils.ImageWidth.w3840.rawValue) {
                adjusted = resized
            }
            thumbnailURL = URL(string: adjusted) ?? URL(string: thumbnailString) ?? imageURL
        }

        // The image description service returns a language but not a language variant code.
        // The language code is correct here.
        let isRTL = MWKLanguageLinkController.isLanguageRTL(forContentLanguageCode: image.description?.lang)

        self.init(
            canonicalPageTitle: title,
            imageDescription: image.description?.text ?? "",
            imageDescriptionIsRTL: isRTL,
            imageThumbURL: thumbnailURL,
            imageURL: imageURL,
            imageWidth: image.image?.width.map { NSNumber(value: $0) },
            imageHeight: image.image?.height.map { NSNumber(value: $0) }
        )
        propagateLanguageVariantCode(languageVariantCode)
    }

    /// The URL of the image at a size that fills the given area.
    @objc(getImageURLForWidth:height:)
    public func getImageURL(forWidth width: Double, height: Double) -> URL? {
        guard let imageWidth = imageWidth?.doubleValue, let imageHeight = imageHeight?.doubleValue, imageWidth > 0, imageHeight > 0 else {
            return imageThumbURL
        }
        let maxScale = max(width / imageWidth, height / imageHeight)
        var targetWidth = imageWidth * maxScale
        let targetHeight = imageHeight * maxScale

        // The thumbnail service only limits the width. A tall panorama can become very large.
        // Limit the height to prevent this.
        let heightLimit = 1.5 * Double(ImageUtils.ImageWidth.w3840.rawValue)
        if targetHeight > heightLimit {
            targetWidth *= heightLimit / targetHeight
        }

        // The service cannot return a width larger than the original width.
        if targetWidth > imageWidth {
            return imageURL
        }

        let standardizedSize: Int
        if targetWidth <= Double(ImageUtils.ImageWidth.w1280.rawValue) {
            standardizedSize = ImageUtils.ImageWidth.w1280.rawValue
        } else if targetWidth <= Double(ImageUtils.ImageWidth.w1920.rawValue) {
            standardizedSize = ImageUtils.ImageWidth.w1920.rawValue
        } else {
            standardizedSize = ImageUtils.ImageWidth.w3840.rawValue
        }

        guard let adjusted = WMFChangeImageSourceURLSizePrefix(imageThumbURL.absoluteString, standardizedSize),
              let adjustedURL = URL(string: adjusted) else {
            return imageThumbURL
        }
        return adjustedURL
    }

    // MARK: - Language variant

    /// Set the language variant code on the URL properties. The content group calls this method after it decodes the object.
    public func propagateLanguageVariantCode(_ languageVariantCode: String?) {
        imageThumbURL.wmf_languageVariantCode = languageVariantCode
        imageURL.wmf_languageVariantCode = languageVariantCode
    }

    // MARK: - NSSecureCoding

    public static var supportsSecureCoding: Bool { true }

    private enum Key {
        static let canonicalPageTitle = "canonicalPageTitle"
        static let imageDescription = "imageDescription"
        static let imageDescriptionIsRTL = "imageDescriptionIsRTL"
        static let imageThumbURL = "imageThumbURL"
        static let imageURL = "imageURL"
        static let imageWidth = "imageWidth"
        static let imageHeight = "imageHeight"
    }

    public init?(coder: NSCoder) {
        guard let imageURL = coder.decodeObject(of: NSURL.self, forKey: Key.imageURL) as URL? else {
            return nil
        }
        self.imageURL = imageURL
        imageThumbURL = (coder.decodeObject(of: NSURL.self, forKey: Key.imageThumbURL) as URL?) ?? imageURL
        canonicalPageTitle = (coder.decodeObject(of: NSString.self, forKey: Key.canonicalPageTitle) as String?) ?? ""
        imageDescription = (coder.decodeObject(of: NSString.self, forKey: Key.imageDescription) as String?) ?? ""
        imageDescriptionIsRTL = coder.decodeObject(of: NSNumber.self, forKey: Key.imageDescriptionIsRTL)?.boolValue ?? false
        imageWidth = coder.decodeObject(of: NSNumber.self, forKey: Key.imageWidth)
        imageHeight = coder.decodeObject(of: NSNumber.self, forKey: Key.imageHeight)
        super.init()
    }

    public func encode(with coder: NSCoder) {
        coder.encode(canonicalPageTitle, forKey: Key.canonicalPageTitle)
        coder.encode(imageDescription, forKey: Key.imageDescription)
        coder.encode(NSNumber(value: imageDescriptionIsRTL), forKey: Key.imageDescriptionIsRTL)
        coder.encode(imageThumbURL, forKey: Key.imageThumbURL)
        coder.encode(imageURL, forKey: Key.imageURL)
        coder.encode(imageWidth, forKey: Key.imageWidth)
        coder.encode(imageHeight, forKey: Key.imageHeight)
    }

    // MARK: - Equality

    public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? WMFFeedImage else {
            return false
        }
        return canonicalPageTitle == other.canonicalPageTitle
            && imageDescription == other.imageDescription
            && imageURL == other.imageURL
            && imageThumbURL == other.imageThumbURL
    }

    public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(canonicalPageTitle)
        hasher.combine(imageURL)
        return hasher.finalize()
    }
}
