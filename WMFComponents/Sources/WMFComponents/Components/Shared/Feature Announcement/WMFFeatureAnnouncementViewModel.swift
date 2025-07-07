import Foundation
import UIKit

public class WMFFeatureAnnouncementViewModel {
    let title: String
    let body: String
    let primaryButtonTitle: String
    let gifName: String?
    let altText: String?
    let image: UIImage?
    let backgroundImage: UIImage?
    let backgroundImageHeight: CGFloat
    var primaryButtonAction: (() -> Void)
    var closeButtonAction: (() -> Void)?
    
    public init(title: String, body: String, primaryButtonTitle: String, image: UIImage? = nil, backgroundImage: UIImage? = nil, backgroundImageHeight: CGFloat = 140, gifName: String? = nil, altText: String? = nil, primaryButtonAction: @escaping () -> Void, closeButtonAction: (() -> Void)? = nil) {
        self.title = title
        self.body = body
        self.primaryButtonTitle = primaryButtonTitle
        self.image = image
        self.backgroundImage = backgroundImage
        self.backgroundImageHeight = backgroundImageHeight
        self.primaryButtonAction = primaryButtonAction
        self.closeButtonAction = closeButtonAction
        self.gifName = gifName
        self.altText = altText
    }
}
