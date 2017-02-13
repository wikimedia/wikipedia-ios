import UIKit


protocol ArticlePopoverViewControllerDelegate: NSObjectProtocol {
    func articlePopoverViewController(articlePopoverViewController: ArticlePopoverViewController, didSelectAction: WMFArticleAction)
}

class ArticlePopoverViewController: UIViewController {

    weak var delegate: ArticlePopoverViewControllerDelegate?
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    @IBOutlet weak var articleSummaryView: UIView!
    
    var article: WMFArticle?
    
    override func viewDidLoad() {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        articleSummaryView.addGestureRecognizer(tapGR)
    }
    
    func handleTapGesture(_ tapGR: UITapGestureRecognizer) {
        switch tapGR.state {
        case .recognized:
            delegate?.articlePopoverViewController(articlePopoverViewController: self, didSelectAction: .read)
        default:
            break
        }
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


