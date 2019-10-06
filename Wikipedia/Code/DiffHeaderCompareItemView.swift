
import UIKit

class DiffHeaderCompareItemView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var timestampLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var tagsLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    @IBOutlet var userIconImageView: UIImageView!
    var minHeight: CGFloat {
        return timestampLabel.frame.maxY
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderCompareItemView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func update(_ viewModel: DiffHeaderCompareItemViewModel) {
        headingLabel.text = viewModel.heading
        timestampLabel.text = viewModel.timestampString
        if #available(iOS 13.0, *) {
            userIconImageView.image = UIImage(systemName: "person.fill")
        } else {
            userIconImageView.isHidden = true //TONITODO: get asset for this
        }
        usernameLabel.text = viewModel.username
        tagsLabel.text = "" //TONITODO: tags
        summaryLabel.text = viewModel.summary //TONITODO: italic for some of this
    }
}
