import UIKit

public protocol AnnouncementCollectionViewCellDelegate: NSObjectProtocol {
    func announcementCellDidTapDismiss(_ cell: AnnouncementCollectionViewCell)
    func announcementCellDidTapActionButton(_ cell: AnnouncementCollectionViewCell)
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL: URL)
}

open class AnnouncementCollectionViewCell: CollectionViewCell {
    public weak var delegate: AnnouncementCollectionViewCellDelegate?
    
    public let imageView = UIImageView()
    private let messageTextView = UITextView()
    public let actionButton = UIButton()
    public let dismissButton = UIButton()
    private let captionTextView = UITextView()
    public let captionSeparatorView = UIView()
    public let messageSpacing: CGFloat = 20
    public let buttonMargin: CGFloat = 40
    public let actionButtonHeight: CGFloat = 40
    public let dismissButtonSpacing: CGFloat = 8
    public let dismissButtonHeight: CGFloat = 32
    public var imageViewDimension: CGFloat = 150
    public let captionSpacing: CGFloat = 20

    open override func setup() {
        layoutMargins = UIEdgeInsets(top: 8, left: 15, bottom: 8, right: 15)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        messageTextView.isEditable = false
        messageTextView.delegate = self
        addSubview(messageTextView)
        
        addSubview(actionButton)
        
        addSubview(dismissButton)
        
        addSubview(captionSeparatorView)
        
        captionTextView.isEditable = false
        captionTextView.delegate = self
        addSubview(captionTextView)
        
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        actionButton.titleLabel?.numberOfLines = 0
        actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)

        dismissButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 8, right: 15)
        dismissButton.titleLabel?.numberOfLines = 0
        dismissButton.setTitle(CommonStrings.dismissButtonTitle, for: .normal)
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
        
        super.setup()
    }
    
    @objc func actionButtonPressed() {
        delegate?.announcementCellDidTapActionButton(self)
    }
    
    @objc func dismissButtonPressed() {
        delegate?.announcementCellDidTapDismiss(self)
    }
    
    // This method is called to reset the cell to the default configuration. It is called on initial setup and prepareForReuse. Subclassers should call super.
    override open func reset() {
        super.reset()
        imageViewDimension = 150
        updateFonts(with: traitCollection)
        captionHTML = nil
        messageHTML = nil
        isImageViewHidden = true
        isUrgent = false
    }
    
    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        actionButton.titleLabel?.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        dismissButton.titleLabel?.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        updateCaptionTextViewWithAttributedCaption()
    }
    
    public var isImageViewHidden = false {
        didSet {
            imageView.isHidden = isImageViewHidden
            setNeedsLayout()
        }
    }
    
    fileprivate var isCaptionHidden = false {
        didSet {
            captionSeparatorView.isHidden = isCaptionHidden
            captionTextView.isHidden = isCaptionHidden
            setNeedsLayout()
        }
    }

    fileprivate func updateCaptionTextViewWithAttributedCaption() {
        guard let html = captionHTML else {
            isCaptionHidden = true
            return
        }
        let attributedText = html.byAttributingHTML(with: .footnote, matching: traitCollection)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        let color = captionTextView.textColor ?? UIColor.black
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: pStyle, NSAttributedString.Key.foregroundColor: color]
        attributedText.addAttributes(attributes, range: NSMakeRange(0, attributedText.length))
        captionTextView.attributedText = attributedText
        isCaptionHidden = false
    }
    
    public var captionHTML: String? {
        didSet {
            updateCaptionTextViewWithAttributedCaption()
        }
    }
    
    public var isUrgent: Bool = false
    private var messageUnderlineColor: UIColor?
    private func updateMessageTextViewWithAttributedMessage() {
        guard let html = messageHTML else {
            messageTextView.attributedText = nil
            return
        }
        let attributedText = html.byAttributingHTML(with: .subheadline, matching: traitCollection, underlineColor: messageUnderlineColor)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        pStyle.lineHeightMultiple = 1.5
        let color = messageTextView.textColor ?? UIColor.black
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: pStyle, NSAttributedString.Key.foregroundColor: color]
        attributedText.addAttributes(attributes, range: NSMakeRange(0, attributedText.length))
        messageTextView.attributedText = attributedText
    }
    
    public var messageHTML: String? {
        didSet {
            updateMessageTextViewWithAttributedMessage()
        }
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = layoutWidth(for: size)
        let displayScale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
        var origin = CGPoint(x: layoutMargins.left + layoutMarginsAdditions.left, y: 0)
        
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += messageSpacing
        
        let messageTextSize = messageTextView.sizeThatFits(CGSize(width: widthMinusMargins, height: CGFloat.greatestFiniteMagnitude))
        let messageFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: messageTextSize.height))
        if (apply) {
            messageTextView.frame = messageFrame
        }
        origin.y += messageFrame.layoutHeight(with: messageSpacing)
        
        let buttonMinimumWidth = min(250, widthMinusMargins)
        
        origin.y += actionButton.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, minimumWidth: buttonMinimumWidth, horizontalAlignment: .center, spacing: dismissButtonSpacing, apply: apply)
        origin.y += dismissButton.wmf_preferredHeight(at: origin, maximumWidth: widthMinusMargins, minimumWidth: buttonMinimumWidth, horizontalAlignment: .center, spacing: 0, apply: apply)

        
        if !isCaptionHidden {
            origin.y += dismissButtonSpacing
            let separatorFrame = CGRect(x: origin.x, y: origin.y, width: widthMinusMargins, height: 1.0 / displayScale)
            if (apply) {
                captionSeparatorView.frame = separatorFrame
            }
            origin.y += separatorFrame.height
            origin.y += captionSpacing
            let captionTextViewSize = captionTextView.sizeThatFits(CGSize(width: widthMinusMargins, height: CGFloat.greatestFiniteMagnitude))
            let captionFrame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: captionTextViewSize.height))
            if (apply) {
                captionTextView.frame = captionFrame
            }
            origin.y += captionFrame.height
            origin.y += captionSpacing
        } else {
            origin.y += layoutMargins.bottom
        }
    
        return CGSize(width: size.width, height: origin.y)
    }
}


extension AnnouncementCollectionViewCell: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.announcementCell(self, didTapLinkURL: URL)
        return false
    }
}

extension AnnouncementCollectionViewCell: Themeable {
    @objc(applyTheme:)
    public func apply(theme: Theme) {
        setBackgroundColors(theme.colors.cardBackground, selected: theme.colors.selectedCardBackground)
        messageTextView.textColor = theme.colors.primaryText
        messageTextView.backgroundColor = .clear
        dismissButton.setTitleColor(theme.colors.secondaryText, for: .normal)
        imageView.backgroundColor = theme.colors.midBackground
        imageView.alpha = theme.imageOpacity
        actionButton.setTitleColor(theme.colors.link, for: .normal)
        actionButton.backgroundColor = theme.colors.cardButtonBackground
        if isUrgent {
            messageUnderlineColor = theme.colors.error
            layer.borderWidth = 3
            layer.borderColor = theme.colors.error.cgColor
            layer.cornerRadius = Theme.exploreCardCornerRadius
        } else {
            layer.borderWidth = 0
            layer.cornerRadius = 0
            messageUnderlineColor = nil
        }
        actionButton.layer.cornerRadius = 5
        captionSeparatorView.backgroundColor = theme.colors.border
        captionTextView.textColor = theme.colors.secondaryText
        captionTextView.backgroundColor = .clear
        updateCaptionTextViewWithAttributedCaption()
        updateMessageTextViewWithAttributedMessage()
    }
}
