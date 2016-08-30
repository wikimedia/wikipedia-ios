import UIKit

public class WMFArticlePreviewViewController: UIViewController {

    @IBOutlet weak public var imageView: UIImageView!
    @IBOutlet weak public var subtitleLabel: UILabel!
    @IBOutlet weak public var titleLabel: UILabel!
    
    public required init() {
        let bundle = NSBundle(identifier: "org.wikimedia.WMFUI")
        super.init(nibName: "WMFArticlePreviewViewController", bundle: bundle)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
