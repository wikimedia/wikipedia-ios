import UIKit

enum DiffHeaderUsernameDestination {
    case userContributions
    case userTalkPage
    case userPage
}

class DiffHeaderExtendedView: UICollectionReusableView, Themeable {
    lazy var contentView: DiffHeaderExtendedContentView = {
        let view = DiffHeaderExtendedContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var tappedHeaderUsernameAction: ((Username, DiffHeaderUsernameDestination) -> Void)? {
        get {
            return contentView.tappedHeaderUsernameAction
        }
        set {
            contentView.tappedHeaderUsernameAction = newValue
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        addSubview(contentView)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: contentView.topAnchor),
            leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func update(_ new: DiffHeaderViewModel, theme: Theme) {
        contentView.update(new, theme: theme)
    }
    
    func apply(theme: Theme) {
        contentView.apply(theme: theme)
    }
}

class DiffHeaderExtendedContentView: SetupView {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        return stackView
    }()
    
    private lazy var summaryView: DiffHeaderSummaryView = {
        let view = DiffHeaderSummaryView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var editorView: DiffHeaderEditorView = {
        let view = DiffHeaderEditorView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var compareView: DiffHeaderCompareView = {
        let view = DiffHeaderCompareView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var topDivView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var summaryDivView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var editorDivView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var compareDivView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
 
    private var viewModel: DiffHeaderViewModel?
    
    override func setup() {
        super.setup()
        
        stackView.addArrangedSubview(topDivView)
        stackView.addArrangedSubview(summaryView)
        stackView.addArrangedSubview(summaryDivView)
        stackView.addArrangedSubview(editorView)
        stackView.addArrangedSubview(editorDivView)
        stackView.addArrangedSubview(compareView)
        stackView.addArrangedSubview(compareDivView)
        
        addSubview(stackView)
        
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: stackView.topAnchor),
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
            topDivView.heightAnchor.constraint(equalToConstant: 1),
            summaryDivView.heightAnchor.constraint(equalToConstant: 1),
            editorDivView.heightAnchor.constraint(equalToConstant: 1),
            compareDivView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
    
    var tappedHeaderUsernameAction: ((Username, DiffHeaderUsernameDestination) -> Void)? {
        get {
            return editorView.tappedHeaderUsernameAction
        }
        set {
            editorView.tappedHeaderUsernameAction = newValue
            compareView.tappedHeaderUsernameAction = newValue
        }
    }
    
    func update(_ new: DiffHeaderViewModel, theme: Theme) {
        
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
        
        apply(theme: theme)
    }
}

extension DiffHeaderExtendedContentView: Themeable {

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        summaryView.apply(theme: theme)
        editorView.apply(theme: theme)
        compareView.apply(theme: theme)
        topDivView.backgroundColor = theme.colors.baseBackground
        summaryDivView.backgroundColor = theme.colors.baseBackground
        editorDivView.backgroundColor = theme.colors.baseBackground
        compareDivView.backgroundColor = theme.colors.baseBackground
    }
}
