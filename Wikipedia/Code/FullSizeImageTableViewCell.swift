import UIKit

class FullSizeImageTableViewCell: UITableViewCell {
    static let identifier = "org.wikimedia.fullsizeimage"
    @IBOutlet weak var fullSizeImageView: UIImageView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        fullSizeImageView.wmf_reset()   
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.wmf_makeCellDividerBeEdgeToEdge()
    }
}
