import UIKit
import WMFData

public struct WMFYearInReviewSlideViewModel: Identifiable {

    public struct LocalizedStrings {
        public var accessibilityLabel: String?

        public init(accessibilityLabel: String? = nil) {
            self.accessibilityLabel = accessibilityLabel
        }
    }

    /// An article whose thumbnail fills an image property in the .riv.
    public struct ArticleThumbnail: Hashable, Sendable {
        public let project: WMFProject
        public let title: String

        public init(project: WMFProject, title: String) {
            self.project = project
            self.title = title
        }
    }

    /// Which color the app draws its own controls in above the animation.
    public enum ContentStyle {
        /// Light controls, for dark artwork.
        case light
        /// Dark controls, for light artwork.
        case dark

        public var color: UIColor {
            self == .light ? WMFColor.white : WMFColor.gray700
        }
    }

    public let id: String
    public let loggingID: String
    public let animation: WMFRiveAnimation?
    public let text: [WMFRiveText: String]
    public let numbers: [WMFRiveNumber: Double]
    /// Loaded when the slide shows. A property with no thumbnail keeps the placeholder in the .riv.
    public let articleThumbnails: [WMFRiveImage: ArticleThumbnail]
    public let localizedStrings: LocalizedStrings
    public let showsShareButton: Bool
    public let showsDonateButton: Bool
    /// The style until the slide loads, and the style if the .riv does not set `lightContentFlag`.
    public let contentStyle: ContentStyle
    /// A boolean in the .riv that the artwork sets. True asks for light controls. When the slide
    /// loads, its value replaces `contentStyle`.
    public let lightContentFlag: WMFRiveBool?
    /// Text runs that the slide keeps on one line.
    public let singleLineFits: [WMFRiveSingleLineFit]

    public init(
        id: String,
        loggingID: String,
        animation: WMFRiveAnimation? = nil,
        text: [WMFRiveText: String] = [:],
        numbers: [WMFRiveNumber: Double] = [:],
        articleThumbnails: [WMFRiveImage: ArticleThumbnail] = [:],
        localizedStrings: LocalizedStrings = LocalizedStrings(),
        showsShareButton: Bool = true,
        showsDonateButton: Bool = true,
        contentStyle: ContentStyle = .light,
        lightContentFlag: WMFRiveBool? = nil,
        singleLineFits: [WMFRiveSingleLineFit] = []
    ) {
        self.id = id
        self.loggingID = loggingID
        self.animation = animation
        self.text = text
        self.numbers = numbers
        self.articleThumbnails = articleThumbnails
        self.localizedStrings = localizedStrings
        self.showsShareButton = showsShareButton
        self.showsDonateButton = showsDonateButton
        self.contentStyle = contentStyle
        self.lightContentFlag = lightContentFlag
        self.singleLineFits = singleLineFits
    }

    public var prefersLightContent: Bool {
        contentStyle == .light
    }

    public var contentColor: UIColor {
        contentStyle.color
    }
}
