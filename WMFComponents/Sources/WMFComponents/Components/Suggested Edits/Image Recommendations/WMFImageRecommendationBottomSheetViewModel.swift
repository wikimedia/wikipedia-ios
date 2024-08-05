import UIKit
import WMFData

public class  WMFImageRecommendationBottomSheetViewModel {

    let pageId: Int
    let headerTitle: String
    let imageThumbnail: UIImage?
    let imageLink: String
    let thumbLink: String
    let imageTitle: String
    var imageDescription: String?
    let reason: String
    let yesButtonTitle: String
    let noButtonTitle: String
    let notSureButtonTitle: String

    public init(pageId: Int, headerTitle: String, imageThumbnail: UIImage?, imageLink: String, thumbLink: String, imageTitle: String, imageDescription: String? = nil, reason: String, yesButtonTitle: String, noButtonTitle: String, notSureButtonTitle: String) {
        self.pageId = pageId
        self.headerTitle = headerTitle
        self.imageThumbnail = imageThumbnail
        self.imageLink = imageLink
        self.thumbLink = thumbLink
        self.imageTitle = imageTitle
        self.imageDescription = imageDescription
        self.reason = reason
        self.yesButtonTitle = yesButtonTitle
        self.noButtonTitle = noButtonTitle
        self.notSureButtonTitle = notSureButtonTitle

        update()
    }

    private func update() {
        if let description = imageDescription {
            imageDescription = getCleanDescription(from: description)
        }
    }

    private func getCleanDescription(from input: String) -> String? {
        return input.removingHTML
    }

}
