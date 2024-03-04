import UIKit
import WKData

public struct WKImageRecommendationBottomSheetViewModel {

    let headerTitle: String
    let headerIcon: UIImage?
    let image: UIImage
    let imageLink: String
    let imageTitle: String
    let imageDescription: String
    let yesButtonTitle: String
    let noButtonTitle: String
    let notSureButtonTitle: String
    var imageRecommendations: [WKImageRecommendation]?
    var pageID: String

    public init(headerTitle: String, headerIcon: UIImage?, image: UIImage, imageLink: String, imageTitle: String, imageDescription: String, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String, pageID: String) {
        self.headerTitle = headerTitle
        self.headerIcon = headerIcon
        self.image = image
        self.imageLink = imageLink
        self.imageTitle = imageTitle
        self.imageDescription = imageDescription
        self.yesButtonTitle = yesButtonTitle
        self.noButtonTitle = noButtonTitle
        self.notSureButtonTitle = notSureButtonTitle
        self.pageID = pageID
    }

}
