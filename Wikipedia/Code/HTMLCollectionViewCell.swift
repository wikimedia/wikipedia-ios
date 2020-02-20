import Foundation

 public protocol HTMLCollectionViewCellDelegate: AnyObject {
    func collectionViewCell(_ HTMLCollectionViewCell: HTMLCollectionViewCell, didTapLinkWith url: URL)
}

 public class HTMLCollectionViewCell: CollectionViewCell {
    public weak var delegate: HTMLCollectionViewCellDelegate?
    public var html: String? {
        didSet {
            update()
        }
    }
    
    public var titleHTML: String? {
        didSet {
            update()
        }
    }


    private let textView = UITextView()
    private let cardView = UIView()

    let spacing: CGFloat = 12
    
     open override func setup() {
        cardView.cornerRadius = 8
        addSubview(cardView)

        textView.layoutMargins = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.delegate = self
        textView.backgroundColor = .clear
        addSubview(textView)
        super.setup()
    }

     private func update() {
        textView.attributedText = html?.byAttributingHTML(with: .body, matching: traitCollection, color: textView.textColor, linkColor: textView.tintColor)
    }

     override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        update()
    }

    // MARK: Layout
           
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = layoutWidth(for: size) - 2 * spacing
        let margins = calculatedLayoutMargins
        var origin = CGPoint(x: margins.left + spacing, y: margins.top + spacing)
        let textSize = textView.sizeThatFits(CGSize(width: widthMinusMargins, height: CGFloat.greatestFiniteMagnitude))
        let textFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: textSize.height))
        if (apply) {
            textView.frame = textFrame
            cardView.frame = bounds.inset(by: margins)
        }
        origin.y += textSize.height + spacing + margins.bottom
        return CGSize(width: size.width, height: origin.y)
    }
}

 extension HTMLCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        tintColor = theme.colors.link
        selectedBackgroundView?.backgroundColor = .clear
        backgroundView?.backgroundColor = .clear
        textView.textColor = theme.colors.primaryText
        cardView.backgroundColor = theme.colors.paperBackground
        update()
    }
}

 extension HTMLCollectionViewCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.collectionViewCell(self, didTapLinkWith: URL)
        return false
    }
}
