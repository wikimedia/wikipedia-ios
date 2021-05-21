import Foundation
import UIKit

extension UIView {
    /// hat tip: https://stackoverflow.com/questions/17145049/capture-uiview-and-save-as-image and https://stackoverflow.com/questions/4334233/how-to-capture-uiview-to-uiimage-without-loss-of-quality-on-retina-display
    var asImage: UIImage? {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        guard let context = UIGraphicsGetCurrentContext() else {
            UIGraphicsEndImageContext()
            return nil
        }
        layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
        UIGraphicsEndImageContext()
    }
}
