import UIKit

class CreateReadingListViewController: UIViewController {
    
    @IBOutlet var textViews: [ThemeableTextView]!
    @IBOutlet weak var closeButton: UIButton!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var readingListNameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var createReadingListButton: UIButton!
    
    fileprivate var theme: Theme = Theme.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        apply(theme: theme)
    }
    
    @IBAction func closeButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    init(theme: Theme) {
        self.theme = theme
        super.init(nibName: "CreateReadingListViewController", bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension CreateReadingListViewController: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        
        guard viewIfLoaded != nil else {
            return
        }
        
        view.backgroundColor = theme.colors.paperBackground
        view.tintColor = theme.colors.link
        
        for textView in textViews {
            textView.apply(theme: theme)
        }
        
        titleLabel.textColor = theme.colors.primaryText
        readingListNameLabel.textColor = theme.colors.secondaryText
        descriptionLabel.textColor = theme.colors.secondaryText
       
    }
}
