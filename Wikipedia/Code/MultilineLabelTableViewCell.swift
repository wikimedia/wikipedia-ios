import UIKit

class MultilineLabelTableViewCell: UITableViewCell {
    static let identifier = "org.wikimedia.multiline"
    
    @IBOutlet weak var multilineLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        self.wmf_makeCellDividerBeEdgeToEdge()
    }
}
