
import UIKit

class DiffHeaderSummaryView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var tagLabel: UILabel!
    @IBOutlet var summaryLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderSummaryView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    func update(_ viewModel: DiffHeaderEditSummaryViewModel) {
        headingLabel.text = viewModel.heading
        tagLabel.text = "" //TONITODO: tags
        summaryLabel.text = viewModel.summary
    }

}
