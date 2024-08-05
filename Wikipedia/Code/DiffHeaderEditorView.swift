import WMFComponents

class DiffHeaderEditorView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet var headingLabel: UILabel!
    @IBOutlet var userIconImageView: UIImageView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var numberOfEditsLabel: UILabel!
    @IBOutlet var userStackView: UIStackView!
    
    private var tapGestureRecognizer: UITapGestureRecognizer?
    weak var delegate: DiffHeaderActionDelegate?
    
    private var viewModel: DiffHeaderEditorViewModel?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        if let tapGestureRecognizer = tapGestureRecognizer {
            userStackView.addGestureRecognizer(tapGestureRecognizer)
        }
        userStackView.accessibilityTraits = [.link]
    }
    
    func update(_ viewModel: DiffHeaderEditorViewModel) {
        
        self.viewModel = viewModel
        
        headingLabel.text = viewModel.heading
        usernameLabel.text = viewModel.username
        userIconImageView.image = UIImage(named: "user-edit")
        
        if let numberOfEditsForDisplay = viewModel.numberOfEditsForDisplay,
        !numberOfEditsForDisplay.isEmpty {
            numberOfEditsLabel.text = numberOfEditsForDisplay
            numberOfEditsLabel.isHidden = false
        } else {
            numberOfEditsLabel.isHidden =  true
        }
        
        updateFonts(with: traitCollection)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts(with: traitCollection)
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !UIAccessibility.isVoiceOverRunning else {
            return super.point(inside: point, with: event)
        }
        let userStackViewConvertedPoint = self.convert(point, to: userStackView)
        return userStackView.point(inside: userStackViewConvertedPoint, with: event)
    }
    
    @objc func tappedUserWithSender(_ sender: UITapGestureRecognizer) {
        if let viewModel,
           let username = viewModel.username {
            WatchlistFunnel.shared.logDiffTapSingleEditorName(project: viewModel.project)
            delegate?.tappedUsername(username: username, destination: .userPage)
        }
    }
}

private extension DiffHeaderEditorView {
    
    func commonInit() {
        Bundle.main.loadNibNamed(DiffHeaderEditorView.wmf_nibName(), owner: self, options: nil)
            addSubview(contentView)
            contentView.frame = self.bounds
            contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tappedUserWithSender(_:)))
        
        let isRTL = effectiveUserInterfaceLayoutDirection == .rightToLeft
        numberOfEditsLabel.textAlignment = isRTL ? .left : .right
    }
    
    func updateFonts(with traitCollection: UITraitCollection) {
    
        headingLabel.font = WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
        usernameLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        numberOfEditsLabel.font = WMFFont.for(.callout, compatibleWith: traitCollection)
    }
}

extension DiffHeaderEditorView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
        headingLabel.textColor = theme.colors.secondaryText
        usernameLabel.textColor = theme.colors.link
        userIconImageView.tintColor = theme.colors.link
        numberOfEditsLabel.textColor = theme.colors.secondaryText
    }
}
