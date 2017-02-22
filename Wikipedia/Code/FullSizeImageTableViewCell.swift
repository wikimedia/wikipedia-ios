import UIKit

class FullSizeImageTableViewCell: UITableViewCell {
    static let identifier = "org.wikimedia.fullsizeimage"
    @IBOutlet weak var fullSizeImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.resetContentMode();
        fullSizeImageView.wmf_reset()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.resetContentMode();
        self.wmf_makeDividerBeEdgeToEdge()
    }
    
    func resetContentMode() {
        if (UI_USER_INTERFACE_IDIOM() == .pad) {
            fullSizeImageView.contentMode = .scaleAspectFit;
        } else {
            fullSizeImageView.contentMode = .scaleAspectFill;
        }
    }
}
