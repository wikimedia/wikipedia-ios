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
    public let contentStyle: ContentStyle

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
        contentStyle: ContentStyle = .light
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
    }

    public var prefersLightContent: Bool {
        contentStyle == .light
    }

    public var contentColor: UIColor {
        prefersLightContent ? WMFColor.white : WMFColor.gray700
    }
}
