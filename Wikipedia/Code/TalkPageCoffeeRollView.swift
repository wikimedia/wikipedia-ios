import UIKit

final class TalkPageCoffeeRollView: SetupView {

    // MARK: - Properties

    var theme: Theme!
    var viewModel: TalkPageCoffeeRollViewModel!
    
    weak var linkDelegate: TalkPageTextViewLinkHandling?

    // MARK: - UI Elements

    lazy var textView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isScrollEnabled = true
        textView.isEditable = false
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
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
        addSubview(textView)
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: topAnchor),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor),
            textView.leadingAnchor.constraint(equalTo: readableContentGuide.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: readableContentGuide.trailingAnchor)
        ])
    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCoffeeRollViewModel) {
        self.viewModel = viewModel
        textView.attributedText = viewModel.coffeeRollText?.byAttributingHTML(with: .callout, boldWeight: .semibold, matching: traitCollection, color: theme.colors.primaryText, linkColor: theme.colors.link, handlingLists: true, handlingSuperSubscripts: true)
    }

}

extension TalkPageCoffeeRollView: Themeable {

    func apply(theme: Theme) {
        self.theme = theme

        backgroundColor = theme.colors.paperBackground

        textView.backgroundColor = theme.colors.paperBackground
        configure(viewModel: viewModel)
    }

}

extension TalkPageCoffeeRollView: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        linkDelegate?.tappedLink(URL, sourceTextView: textView)
        return false
    }

}
