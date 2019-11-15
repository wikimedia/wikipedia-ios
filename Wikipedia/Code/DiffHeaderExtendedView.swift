
import UIKit

protocol DiffHeaderActionDelegate: class {
    func tappedUsername(username: String)
    func tappedRevision(revisionID: Int)
}

class DiffHeaderExtendedView: UIView {
 
    @IBOutlet var contentView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var summaryView: DiffHeaderSummaryView!
    @IBOutlet var editorView: DiffHeaderEditorView!
    @IBOutlet var compareView: DiffHeaderCompareView!
    @IBOutlet var divViews: [UIView]!
    @IBOutlet var summaryDivView: UIView!
    @IBOutlet var editorDivView: UIView!
    @IBOutlet var compareDivView: UIView!
    
    private var viewModel: DiffHeaderViewModel?
    
    weak var delegate: DiffHeaderActionDelegate? {
        get {
            return editorView.delegate
        }
        set {
            editorView.delegate = newValue
            compareView.delegate = newValue
        }
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
        Bundle.main.loadNibNamed(DiffHeaderExtendedView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureHeight(beginSquishYOffset: CGFloat, scrollYOffset: CGFloat) {
        guard let viewModel = viewModel else {
            return
        }
        
        switch viewModel.headerType {
        case .compare:
            compareView.configureHeight(beginSquishYOffset: beginSquishYOffset, scrollYOffset: scrollYOffset)
        default: break
        }
    }
    
    func update(_ new: DiffHeaderViewModel) {
        
        self.viewModel = new
        
        switch new.headerType {
        case .compare(let compareViewModel, _):
            summaryView.isHidden = true
            summaryDivView.isHidden = true
            editorView.isHidden = true
            editorDivView.isHidden = true
            compareView.isHidden = false
            compareDivView.isHidden = false
            compareView.update(compareViewModel)
        case .single(let editorViewModel, let summaryViewModel):
            editorView.isHidden = false
            editorDivView.isHidden = false
            compareView.isHidden = true
            compareDivView.isHidden = true
            if let summary = summaryViewModel.summary, summary.wmf_hasNonWhitespaceText {
                summaryView.isHidden = false
                summaryDivView.isHidden = false
                summaryView.update(summaryViewModel)
            } else {
                summaryView.isHidden = true
                summaryDivView.isHidden = true
            }
            editorView.update(editorViewModel)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        let summaryConvertedPoint = self.convert(point, to: summaryView)
        if summaryView.point(inside: summaryConvertedPoint, with: event) {
            return true
        }
        
        let editorConvertedPoint = self.convert(point, to: editorView)
        if editorView.point(inside: editorConvertedPoint, with: event) {
            return true
        }
        
        let compareConvertedPoint = self.convert(point, to: compareView)
        if compareView.point(inside: compareConvertedPoint, with: event) {
            return true
        }
        
        return false
    }
}

extension DiffHeaderExtendedView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        summaryView.apply(theme: theme)
        editorView.apply(theme: theme)
        compareView.apply(theme: theme)
        
        for view in divViews {
            view.backgroundColor = theme.colors.chromeShadow
        }
    }
}
