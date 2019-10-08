
import UIKit


class DiffHeaderExtendedView: UIView {
 
    @IBOutlet var contentView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var summaryView: DiffHeaderSummaryView!
    @IBOutlet var editorView: DiffHeaderEditorView!
    @IBOutlet var compareView: DiffHeaderCompareView!
    @IBOutlet var divViews: [UIView]!
    @IBOutlet var editorDivView: UIView!
    @IBOutlet var compareDivView: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    private func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderExtendedView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func update(_ viewModel: DiffHeaderViewModel) {
        switch viewModel.type {
        case .compare(let compareViewModel):
            summaryView.isHidden = true
            editorView.isHidden = true
            editorDivView.isHidden = true
            compareView.isHidden = false
            compareDivView.isHidden = false
            compareView.update(compareViewModel)
        case .single(let editorViewModel, let summaryViewModel, _):
            summaryView.isHidden = false
            editorView.isHidden = false
            editorDivView.isHidden = false
            compareView.isHidden = true
            compareDivView.isHidden = true
            summaryView.update(summaryViewModel)
            editorView.update(editorViewModel)
        }
        
        //theming
        backgroundColor = viewModel.theme.colors.paperBackground
        
        for view in divViews {
            view.backgroundColor = viewModel.theme.colors.chromeShadow
        }
    }
}
