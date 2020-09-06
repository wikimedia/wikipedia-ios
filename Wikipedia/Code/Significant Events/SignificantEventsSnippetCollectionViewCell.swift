
import UIKit

protocol SignificantEventsSnippetCollectionViewCellDelegate: class {
    func tappedLink(_ url: URL, cell: SignificantEventsSnippetCollectionViewCell, sourceView: UIView, sourceRect: CGRect?)
}

class SignificantEventsSnippetCollectionViewCell: CollectionViewCell {
    
    weak var delegate: SignificantEventsSnippetCollectionViewCellDelegate?
    
    private let titleTextView = UITextView()
    
    private var theme: Theme?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        
        let adjustedMargins = UIEdgeInsets(top: layoutMargins.top, left: layoutMargins.left, bottom: 0, right: layoutMargins.right)
        

        let titleX = adjustedMargins.left
        
        let titleOrigin = CGPoint(x: titleX, y: adjustedMargins.top)
        let titleMaximumWidth: CGFloat = (size.width - adjustedMargins.right) - titleOrigin.x
        
        let titleTextViewFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: titleMaximumWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = adjustedMargins.top + titleTextViewFrame.size.height + adjustedMargins.bottom
        
        if (apply) {
            titleTextView.textAlignment = .natural
        }
        
        return CGSize(width: size.width, height: finalHeight)
    }
    
    func configure(snippet: NSAttributedString, theme: Theme) {
        apply(theme: theme)
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        //setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        backgroundView?.layer.cornerRadius = 3
        backgroundView?.layer.masksToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 3
        selectedBackgroundView?.layer.masksToBounds = true
        titleTextView.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleTextView.layer.shadowOpacity = 1.0
        titleTextView.layer.shadowRadius = 3
        titleTextView.layer.shadowColor = theme.colors.shadow.cgColor
        titleTextView.layer.masksToBounds = false
        layer.masksToBounds = false
        setupTitle(for: snippet)
        updateFonts(with: traitCollection)
    }
    
    override func reset() {
        super.reset()
        titleTextView.attributedText = nil
    }
    
    private func setupTitle(for attributedText: NSAttributedString) {
        titleTextView.attributedText = attributedText
        titleTextView.textContainer.maximumNumberOfLines = 3
        titleTextView.textContainer.lineBreakMode = .byTruncatingTail
        setNeedsLayout()
    }
    
    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        if let attributedText = titleTextView.attributedText {
            setupTitle(for: attributedText)
        }
    }
    
    override func setup() {
        titleTextView.isEditable = false
        titleTextView.isScrollEnabled = false
        titleTextView.delegate = self
        contentView.addSubview(titleTextView)
        super.setup()
    }
}

//MARK: Themeable

extension SignificantEventsSnippetCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        self.theme = theme
        titleTextView.backgroundColor = theme.colors.paperBackground
        contentView.backgroundColor = theme.colors.paperBackground
    }
}

//MARK: UITextViewDelegate

extension SignificantEventsSnippetCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, cell: self, sourceView: textView, sourceRect: textView.frame(of: characterRange))
        return false
    }
}
