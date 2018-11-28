import UIKit

class TextStyleViewController: UIViewController {

    static func loadFromNib() -> TextStyleViewController {
        return TextStyleViewController(nibName: "TextStyleViewController", bundle: Bundle.main)
    }

}
