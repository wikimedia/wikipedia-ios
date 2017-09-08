import UIKit

class ShareAFactActivityImageItemProvider: UIActivityItemProvider {
    let image: UIImage
    
    required init(image: UIImage) {
        self.image = image
        super.init(placeholderItem: image)
    }
    
    override var item: Any {
        let type = activityType ?? .message
        switch type {
        default:
            return image
        }
    }
}
