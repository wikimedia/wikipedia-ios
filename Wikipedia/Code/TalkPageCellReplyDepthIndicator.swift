import WMFComponents
import WMF

final class TalkPageCellReplyDepthIndicator: SetupView {

    // MARK: - Properties

    private var depth: Int
    private let lineWidth = CGFloat(1)
    private let lineHorizontalSpacing = CGFloat(8)
    private let lineHeightDelta = CGFloat(8)
    private let lineHeightMinimum = CGFloat(3)
    private let maxLines = 10

    fileprivate var theme: Theme = .light

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.spacing = lineHorizontalSpacing
        return stackView
    }()

    lazy var depthLabel: UILabel = {
        let label = UILabel()
        label.font = WMFFont.for(.footnote)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.isAccessibilityElement = false
        return label
    }()
    
    lazy var depthLabelContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    var depthLabelTrailingConstraint: NSLayoutConstraint?
    
    override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            updateSemanticContentAttribute(semanticContentAttribute)
        }
    }

    // MARK: - Lifecycle

    required init(depth: Int) {
        self.depth = depth
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func setup() {
        addSubview(stackView)
        addSubview(depthLabelContainer)
        depthLabelContainer.addSubview(depthLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            depthLabel.leadingAnchor.constraint(equalTo: depthLabelContainer.leadingAnchor),
            depthLabel.trailingAnchor.constraint(equalTo: depthLabelContainer.trailingAnchor),
            depthLabel.topAnchor.constraint(equalTo: depthLabelContainer.topAnchor),
            depthLabel.bottomAnchor.constraint(lessThanOrEqualTo: depthLabelContainer.bottomAnchor),
            
            depthLabelContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            depthLabelContainer.topAnchor.constraint(equalTo: topAnchor),
            depthLabelContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Allows depth label to wrap when it gets too long
        // Activated upon configuration with view model
        let depthLabelTrailingConstraint = depthLabelContainer.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -10)
        self.depthLabelTrailingConstraint = depthLabelTrailingConstraint
    }
    
    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        
        depth = viewModel.replyDepth
        
        isAccessibilityElement = true
        accessibilityLabel = String.localizedStringWithFormat(WMFLocalizedString("talk-page-reply-depth-accessibility-label", value: "Reply depth: %1$d", comment: "Accessibility label for the reply depth indicator. This indicator suggests which reply the text is replying to. %1$d is replaced with the depth number."), depth)
        
        let numberOfLinesToDraw = min(depth, maxLines)
        guard numberOfLinesToDraw > 0 else {
            return
        }
        
        for index in (1...numberOfLinesToDraw) {
            let line = UIView(frame: .zero)
            line.translatesAutoresizingMaskIntoConstraints = false
            
            stackView.addArrangedSubview(line)

            let heightAmountToSubtract = CGFloat(numberOfLinesToDraw - index) * lineHeightDelta
            let potentialHeightConstraint = line.heightAnchor.constraint(equalTo: stackView.heightAnchor, constant: -heightAmountToSubtract)
            potentialHeightConstraint.priority = UILayoutPriority(999)

            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: lineWidth),
                potentialHeightConstraint,
                line.heightAnchor.constraint(greaterThanOrEqualToConstant: lineHeightMinimum)
            ])
        }
        
        let numberRemaining = depth - numberOfLinesToDraw
        depthLabel.text = numberRemaining > 0 ? "+ \(numberRemaining) " : ""
        depthLabelContainer.isHidden = numberRemaining == 0
        depthLabelTrailingConstraint?.isActive = numberRemaining > 0
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        stackView.semanticContentAttribute = semanticContentAttribute
        depthLabel.semanticContentAttribute = semanticContentAttribute
        depthLabelContainer.semanticContentAttribute = semanticContentAttribute
        
        depthLabel.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
    }
}

extension TalkPageCellReplyDepthIndicator: Themeable {

    func apply(theme: Theme) {
        self.theme = theme
        for line in stackView.arrangedSubviews {
            line.backgroundColor = theme.colors.distanceBorder
        }
        depthLabel.textColor = theme.colors.distanceBorder
        depthLabelContainer.backgroundColor = theme.colors.paperBackground
    }

}
