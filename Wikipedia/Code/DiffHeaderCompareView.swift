
import UIKit

class DiffHeaderCompareView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var fromItemView: DiffHeaderCompareItemView!
    @IBOutlet var toItemView: DiffHeaderCompareItemView!
    @IBOutlet var divView: UIView!
    @IBOutlet var innerHeightConstraint: NSLayoutConstraint!
    @IBOutlet var stackView: UIStackView!
    private var maxHeight: CGFloat = 0
    private var minHeight: CGFloat = 0
    private var viewModel: DiffHeaderCompareViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        maxHeight = stackView.frame.height
        minHeight = max(fromItemView.minHeight, toItemView.minHeight)

        if let viewModel = viewModel {
            update(viewModel)
        }
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderCompareView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func update(_ viewModel: DiffHeaderCompareViewModel) {
        self.viewModel = viewModel
        fromItemView.update(viewModel.fromModel)
        toItemView.update(viewModel.toModel)

        let amountToSquish = viewModel.scrollYOffset - viewModel.beginSquishYOffset
        if amountToSquish >= 0 {
            innerHeightConstraint.constant = max((maxHeight - amountToSquish), minHeight)
        } else {
            innerHeightConstraint.constant = maxHeight
        }
        
        //theming
        backgroundColor = viewModel.theme.colors.paperBackground
        contentView.backgroundColor = viewModel.theme.colors.paperBackground
        divView.backgroundColor = viewModel.theme.colors.chromeShadow
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return false
    }
}
