import Foundation
import UIKit

public class WMFFeatureAnnouncementViewModel {
    let title: String
    let body: String
    let primaryButtonTitle: String
    let image: UIImage?
    let backgroundImage: UIImage?
    var primaryButtonAction: (() -> Void)
    var closeButtonAction: (() -> Void)?
    
    public init(title: String, body: String, primaryButtonTitle: String, image: UIImage? = nil, backgroundImage: UIImage? = nil, primaryButtonAction: @escaping () -> Void, closeButtonAction: (() -> Void)? = nil) {
        self.title = title
        self.body = body
        self.primaryButtonTitle = primaryButtonTitle
        self.image = image
        self.backgroundImage = backgroundImage
        self.primaryButtonAction = primaryButtonAction
        self.closeButtonAction = closeButtonAction
    }
}
