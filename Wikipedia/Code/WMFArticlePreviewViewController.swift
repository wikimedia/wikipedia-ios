import UIKit

public class WMFArticlePreviewViewController: UIViewController {

    @IBOutlet weak public var imageView: UIImageView!
    @IBOutlet weak public var subtitleLabel: UILabel!
    @IBOutlet weak public var titleLabel: UILabel!
    @IBOutlet weak public var rankLabel: UILabel!
    @IBOutlet weak public var separatorView: UIView!
    @IBOutlet weak public var viewCountAndSparklineContainerView: UIView!
    @IBOutlet weak public var viewCountLabel: UILabel!
    @IBOutlet weak public var sparklineView: WMFSparklineView!
    
    public required init() {
        let bundle = NSBundle(identifier: "org.wikimedia.WMFUI")
        super.init(nibName: "WMFArticlePreviewViewController", bundle: bundle)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    public override func viewDidLoad() {
        rankLabel.textColor = UIColor.wmf_darkGray()
        separatorView.backgroundColor = UIColor.wmf_darkGray()
    }

}
