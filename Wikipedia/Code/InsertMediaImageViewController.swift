import UIKit

class InsertMediaImageViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!
    @IBOutlet private weak var imageView: UIImageView!

    private var theme = Theme.standard
    private var display = Display.empty

    private enum Display {
        case empty, selected
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        label.text = WMFLocalizedString("insert-media-placeholder-label-text", value: "Select or upload a file", comment: "Text for placeholder label visible when no file was selected or uploaded")
    }
}

extension InsertMediaImageViewController: Themeable {
    func apply(theme: Theme) {
        guard viewIfLoaded != nil else {
            self.theme = theme
            return
        }
        view.backgroundColor = theme.colors.paperBackground
    }
}
