import WMFComponents

final class TalkPageCoffeeRollView: SetupView {

    // MARK: - Properties

    var theme: Theme
    var viewModel: TalkPageCoffeeRollViewModel
    
    weak var linkDelegate: TalkPageTextViewLinkHandling?

    // MARK: - UI Elements
    
    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = false
        textView.isEditable = false
        
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentHuggingPriority(.required, for: .vertical)
        
        textView.delegate = self
        return textView
    }()

    // MARK: - Lifecycle

    required init(theme: Theme, viewModel: TalkPageCoffeeRollViewModel, frame: CGRect) {
        self.theme = theme
        self.viewModel = viewModel
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        addSubview(scrollView)
        scrollView.addSubview(textView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            textView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            textView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            textView.leadingAnchor.constraint(equalTo: scrollView.readableContentGuide.leadingAnchor, constant: 16),
            textView.trailingAnchor.constraint(equalTo: scrollView.readableContentGuide.trailingAnchor, constant: -16),
            textView.widthAnchor.constraint(equalTo: scrollView.readableContentGuide.widthAnchor, constant: -32)
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateFonts()
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCoffeeRollViewModel) {
        self.viewModel = viewModel
        updateFonts()
        updateSemanticContentAttribute(viewModel.semanticContentAttribute)
    }
    
    private func updateFonts() {
        if let coffeeRollText = viewModel.coffeeRollText {
            let styles = HtmlUtils.Styles(font: WMFFont.for(.callout, compatibleWith: traitCollection), boldFont: WMFFont.for(.boldCallout, compatibleWith: traitCollection), italicsFont: WMFFont.for(.italicCallout, compatibleWith: traitCollection), boldItalicsFont: WMFFont.for(.boldItalicCallout, compatibleWith: traitCollection), color: theme.colors.primaryText, linkColor: theme.colors.link, lineSpacing: 1)

            let attributedText = NSMutableAttributedString.mutableAttributedStringFromHtml(coffeeRollText, styles: styles).removingRepetitiveNewlineCharacters()
            textView.attributedText = attributedText
            textView.linkTextAttributes = [.foregroundColor: theme.colors.link]
        }
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        textView.textAlignment = semanticContentAttribute == .forceRightToLeft ? NSTextAlignment.right : NSTextAlignment.left
    }

}

extension TalkPageCoffeeRollView: Themeable {

    func apply(theme: Theme) {
        self.theme = theme

        backgroundColor = theme.colors.paperBackground

        textView.backgroundColor = theme.colors.paperBackground
        
        updateFonts()
        updateSemanticContentAttribute(viewModel.semanticContentAttribute)
    }

}

extension TalkPageCoffeeRollView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }

}
