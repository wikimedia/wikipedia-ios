import UIKit

protocol ArticleAsLivingDocHorizontallyScrollingCellDelegate: AnyObject {
    func tappedLink(_ url: URL)
}

class ArticleAsLivingDocHorizontallyScrollingCell: CollectionViewCell {
    let descriptionTextView = UITextView()
    private var theme: Theme?
    
    weak var delegate: ArticleAsLivingDocHorizontallyScrollingCellDelegate?
    
    override func reset() {
        super.reset()
        descriptionTextView.attributedText = nil
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        fatalError("Must override sizeThatFits in subclass")
    }
    
    func configure(change: ArticleAsLivingDocViewModel.Event.Large.ChangeDetail, theme: Theme, delegate: ArticleAsLivingDocHorizontallyScrollingCellDelegate) {
        
        setupDescription(for: change)
        updateFonts(with: traitCollection)
        
        setNeedsLayout()
        
        apply(theme: theme)
        self.delegate = delegate
    }
    
    func setupDescription(for change: ArticleAsLivingDocViewModel.Event.Large.ChangeDetail) {
        switch change {
        case .snippet(let snippet):
            descriptionTextView.attributedText = snippet.description
        case .reference(let reference):
            descriptionTextView.attributedText = reference.description
        }
    }
    
    override func setup() {
        
        backgroundView?.layer.cornerRadius = 3
        backgroundView?.layer.masksToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 3
        selectedBackgroundView?.layer.masksToBounds = true
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 3
        
        descriptionTextView.isEditable = false
        descriptionTextView.isScrollEnabled = false
        descriptionTextView.delegate = self
        descriptionTextView.textContainer.lineBreakMode = .byTruncatingTail
        descriptionTextView.textContainerInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        contentView.addSubview(descriptionTextView)
        super.setup()
    }
}

extension ArticleAsLivingDocHorizontallyScrollingCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL)
        return false
    }
}

extension ArticleAsLivingDocHorizontallyScrollingCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        backgroundColor = .clear
        descriptionTextView.backgroundColor = .clear
        setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        layer.shadowColor = theme.colors.cardShadow.cgColor
    }
}
