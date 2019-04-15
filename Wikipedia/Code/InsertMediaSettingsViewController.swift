import UIKit

class InsertMediaSettingsViewController: UIViewController {
    private let image: UIImage

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var uploadedImageLabel: UILabel!
    @IBOutlet private weak var imageTitleLabel: UILabel!

    init(image: UIImage) {
        self.image = image
        super.init(nibName: "InsertMediaSettingsViewController", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = image
    }
}
