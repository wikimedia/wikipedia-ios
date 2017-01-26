import UIKit

enum ArticlePopoverViewControllerAction {
    case none
    case save
    case share
    case read
}

protocol ArticlePopoverViewControllerDelegate: NSObjectProtocol {
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: ArticlePopoverViewControllerAction)
}

class ArticlePopoverViewController: UIViewController {

    weak var delegate: ArticlePopoverViewControllerDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    var article: WMFArticle?
    
    override func viewDidLoad() {
        
    }
    
    @IBAction func save(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .save)
    }
    
    @IBAction func share(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .share)
    }
    
    @IBAction func read(_ sender: Any) {
        delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
    }
    
}


