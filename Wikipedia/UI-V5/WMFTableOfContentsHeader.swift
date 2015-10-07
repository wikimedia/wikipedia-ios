
import UIKit

public class WMFTableOfContentsHeader: UIView {

    @IBOutlet var headerLabel: UILabel!
    
    // MARK: - UIView
    public override func awakeFromNib() {
        super.awakeFromNib()
        self.headerLabel.text = localizedStringForKeyFallingBackOnEnglish("table-of-contents-heading").uppercaseString
    }
    
}
