import UIKit
import WKData

public struct WKImageRecommendationBottomSheetViewModel {

    let pageId: Int
    let headerTitle: String
    let headerIcon: UIImage?
    let image: UIImage
    let imageLink: String
    let thumbLink: String
    let imageTitle: String
    let imageDescription: String?
    let yesButtonTitle: String
    let noButtonTitle: String
    let notSureButtonTitle: String

    public init(pageId: Int, headerTitle: String, headerIcon: UIImage?, image: UIImage, imageLink: String, thumbLink: String, imageTitle: String, imageDescription: String?, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String) {
        self.pageId = pageId
        self.headerTitle = headerTitle
        self.headerIcon = headerIcon
        self.image = image
        self.imageLink = imageLink
        self.thumbLink = thumbLink
        self.imageTitle = imageTitle
        self.imageDescription = imageDescription
        self.yesButtonTitle = yesButtonTitle
        self.noButtonTitle = noButtonTitle
        self.notSureButtonTitle = notSureButtonTitle

    }

}
