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
    
    private let textView = UITextView()
    
    open override func setup() {
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
        let widthMinusMargins = layoutWidth(for: size)
        var origin = CGPoint(x: layoutMargins.left + layoutMarginsAdditions.left, y: 0)
        let textSize = textView.sizeThatFits(CGSize(width: widthMinusMargins, height: CGFloat.greatestFiniteMagnitude))
        let textFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: textSize.height))
        if (apply) {
            textView.frame = textFrame
        }
        origin.y += textSize.height + layoutMargins.bottom + layoutMarginsAdditions.bottom
        return CGSize(width: size.width, height: origin.y)
    }
}

extension HTMLCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        tintColor = theme.colors.link
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        backgroundView?.backgroundColor = theme.colors.paperBackground
        textView.textColor = theme.colors.primaryText
        update()
    }
}

extension HTMLCollectionViewCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.collectionViewCell(self, didTapLinkWith: URL)
        return false
    }
}
