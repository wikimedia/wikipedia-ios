
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
        
        let adjustedMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        

        let titleX = adjustedMargins.left
        
        let titleOrigin = CGPoint(x: titleX, y: adjustedMargins.top)
        let titleMaximumWidth: CGFloat = (size.width - adjustedMargins.right) - titleOrigin.x
        
        let titleTextViewFrame = titleTextView.wmf_preferredFrame(at: titleOrigin, maximumWidth: titleMaximumWidth, alignedBy: .forceLeftToRight, apply: apply)
        
        let finalHeight = adjustedMargins.top + titleTextViewFrame.size.height + adjustedMargins.bottom
        
        //tonitodo: these heights still seem wrong
        let textViewExtraHeight = titleTextView.textContainerInset.top
        
        let shadowSize = CGSize(width: size.width, height: finalHeight)
        let totalSize = CGSize(width: size.width, height: finalHeight + textViewExtraHeight)

        if (apply) {
            titleTextView.textAlignment = .natural
            layer.shadowPath = UIBezierPath(roundedRect: CGRect(origin: .zero, size: shadowSize), cornerRadius: backgroundView?.layer.cornerRadius ?? 0).cgPath
        }
        
        return CGSize(width: totalSize.width, height: totalSize.height)
    }
    
    func configure(snippet: NSAttributedString, theme: Theme) {
        apply(theme: theme)
        //setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        setupTitle(for: snippet)
        updateFonts(with: traitCollection)
        
        backgroundView?.layer.cornerRadius = 3
        backgroundView?.layer.masksToBounds = true
        selectedBackgroundView?.layer.cornerRadius = 3
        selectedBackgroundView?.layer.masksToBounds = true
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 3
                
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
        backgroundColor = .clear
        titleTextView.backgroundColor = .clear
        setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        //contentView.backgroundColor = theme.colors.paperBackground
        //setBackgroundColors(theme.colors.subCellBackground, selected: theme.colors.midBackground)
        layer.shadowColor = theme.colors.shadow.cgColor
    }
}

//MARK: UITextViewDelegate

extension SignificantEventsSnippetCollectionViewCell: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.tappedLink(URL, cell: self, sourceView: textView, sourceRect: textView.frame(of: characterRange))
        return false
    }
}
