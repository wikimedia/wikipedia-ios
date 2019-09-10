import UIKit
import WMF

class ImageDimmingExampleViewController: UIViewController {
    
    @IBOutlet weak var exampleImage: UIImageView!
    
    var isImageDimmed: Bool = false {
        didSet {
            exampleImage.alpha = isImageDimmed ? Theme.dimmedImageOpacity : 1.0
        }
    }
}
