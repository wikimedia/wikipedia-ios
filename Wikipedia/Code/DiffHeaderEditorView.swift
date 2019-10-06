
import UIKit

class DiffHeaderEditorView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var userIconImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var numberOfEditsLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderEditorView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func update(_ viewModel: DiffHeaderEditorViewModel) {
        headingLabel.text = viewModel.heading
        usernameLabel.text = viewModel.username
        if #available(iOS 13.0, *) {
            userIconImageView.image = UIImage(systemName: "person.fill")
        } else {
            userIconImageView.isHidden = true //TONITODO: get asset for this
        }
        switch viewModel.state {
        case .loadedNumberOfEdits(let numberOfEdits):
            numberOfEditsLabel.text = String.localizedStringWithFormat(viewModel.numberOfEditsFormat, numberOfEdits)
            numberOfEditsLabel.isHidden = false
        default:
            numberOfEditsLabel.isHidden =  true
        } //TONITODO: activity indicator and stuff
    }
}
