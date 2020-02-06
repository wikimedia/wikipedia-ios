import Foundation

public protocol ReferenceCollectionViewCellDelegate: AnyObject {
    func collectionViewCell(_ cell: ReferenceCollectionViewCell, didTapLinkWith url: URL)
}

public class ReferenceCollectionViewCell: CollectionViewCell {
    public weak var delegate: ReferenceCollectionViewCellDelegate?
    public var html: String? {
        didSet {
            update()
        }
    }
    public var index: Int = -1 {
        didSet {
            label.text = "\(index + 1)."
        }
    }
    
    private let textView = UITextView()
    private let label = UILabel()
    private let spacing: CGFloat = 8

    open override func setup() {
        addSubview(label)
        
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
        textView.attributedText = html?.byAttributingHTML(with: .body, matching: traitCollection, color: textView.textColor, linkColor: textView.tintColor, handlingSuperSubscripts: true)
    }
    
    override public func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        label.font = UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
        update()
    }
    
    // MARK: Layout
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = layoutWidth(for: size)
        
        let labelSizeToFit = CGSize(width: widthMinusMargins, height: .greatestFiniteMagnitude)
        let text = label.text // save previous text
        label.text = "9999" // size with the worst case
        let labelSize = label.sizeThatFits(labelSizeToFit)
        label.text = text // re-set text

        let textViewSizeToFit = CGSize(width: widthMinusMargins - labelSize.width - spacing, height: .greatestFiniteMagnitude)
        let textViewSize = textView.sizeThatFits(textViewSizeToFit)
        
        if (apply) {
            let isRTL = semanticContentAttribute == .forceRightToLeft
            if isRTL {
                let labelX = size.width - calculatedLayoutMargins.left - labelSize.width
                let labelOrigin = CGPoint(x: labelX, y: calculatedLayoutMargins.top)
                label.frame = CGRect(origin: labelOrigin, size: labelSize)
                let textViewOrigin = CGPoint(x: calculatedLayoutMargins.right, y: calculatedLayoutMargins.top)
                textView.frame = CGRect(origin: textViewOrigin, size: textViewSize)
            } else {
                let labelX = calculatedLayoutMargins.left
                let labelOrigin = CGPoint(x: labelX, y: calculatedLayoutMargins.top)
                label.frame = CGRect(origin: labelOrigin, size: labelSize)
                let textViewOrigin = CGPoint(x: calculatedLayoutMargins.left + labelSize.width + spacing, y: calculatedLayoutMargins.top)
                textView.frame = CGRect(origin: textViewOrigin, size: textViewSize)
            }
        }
       
        let maxHeight = max(labelSize.height, textViewSize.height)
        let height = calculatedLayoutMargins.top + calculatedLayoutMargins.bottom + maxHeight
        return CGSize(width: size.width, height: height)
    }
}

extension ReferenceCollectionViewCell: Themeable {
    public func apply(theme: Theme) {
        tintColor = theme.colors.link
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        backgroundView?.backgroundColor = theme.colors.paperBackground
        textView.textColor = theme.colors.primaryText
        label.textColor = theme.colors.primaryText
        update()
    }
}

extension ReferenceCollectionViewCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        delegate?.collectionViewCell(self, didTapLinkWith: URL)
        return false
    }
}
