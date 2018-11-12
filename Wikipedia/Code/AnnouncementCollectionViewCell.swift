import UIKit

public protocol AnnouncementCollectionViewCellDelegate: NSObjectProtocol {
    func announcementCellDidTapDismiss(_ cell: AnnouncementCollectionViewCell)
    func announcementCellDidTapActionButton(_ cell: AnnouncementCollectionViewCell)
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL: URL)
}

open class AnnouncementCollectionViewCell: CollectionViewCell {
    public weak var delegate: AnnouncementCollectionViewCellDelegate?
    
    public let imageView = UIImageView()
    private let messageLabel = UILabel()
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
        
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        addSubview(messageLabel)
        
        addSubview(actionButton)
        
        addSubview(dismissButton)
        
        addSubview(captionSeparatorView)
        
        captionTextView.isEditable = false
        addSubview(captionTextView)
        
        actionButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        actionButton.titleLabel?.numberOfLines = 0
        actionButton.titleLabel?.textAlignment = .center
        actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)

        dismissButton.contentEdgeInsets = UIEdgeInsets(top: 5, left: 15, bottom: 8, right: 15)
        dismissButton.titleLabel?.numberOfLines = 0
        dismissButton.setTitle(CommonStrings.dismissButtonTitle, for: .normal)
        dismissButton.titleLabel?.textAlignment = .center
        dismissButton.addTarget(self, action: #selector(dismissButtonPressed), for: .touchUpInside)
        
        captionTextView.delegate = self
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
        pStyle.alignment = .center
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
    private func updateMessageLabelWithAttributedMessage() {
        guard let html = messageHTML else {
            messageLabel.attributedText = nil
            return
        }
        let attributedText = html.byAttributingHTML(with: .subheadline, matching: traitCollection, underlineColor: messageUnderlineColor)
        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        pStyle.alignment = .center
        pStyle.lineHeightMultiple = 1.5
        let color = messageLabel.textColor ?? UIColor.black
        let attributes: [NSAttributedString.Key : Any] = [NSAttributedString.Key.paragraphStyle: pStyle, NSAttributedString.Key.foregroundColor: color]
        attributedText.addAttributes(attributes, range: NSMakeRange(0, attributedText.length))
        messageLabel.attributedText = attributedText
        isCaptionHidden = false
    }
    
    public var messageHTML: String? {
        didSet {
            updateMessageLabelWithAttributedMessage()
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
        
        let messageFrame = messageLabel.wmf_preferredFrame(at: origin, maximumWidth: widthMinusMargins, minimumWidth: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
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
            // set width first to get proper content size
            captionTextView.frame = CGRect(origin: origin, size: CGSize(width: widthMinusMargins, height: 32))
            let captionTextViewSize = captionTextView.contentSize
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
        messageLabel.textColor = theme.colors.primaryText
        dismissButton.setTitleColor(theme.colors.secondaryText, for: .normal)
        imageView.backgroundColor = theme.colors.midBackground
        imageView.alpha = theme.imageOpacity
        if isUrgent {
            actionButton.setTitleColor(theme.colors.filledButtonText, for: .normal)
            actionButton.backgroundColor = theme.colors.link
            layer.borderWidth = 3
            layer.borderColor = theme.colors.error.cgColor
            layer.cornerRadius = Theme.exploreCardCornerRadius
        } else {
            actionButton.setTitleColor(theme.colors.link, for: .normal)
            actionButton.backgroundColor = theme.colors.cardButtonBackground
            layer.borderWidth = 0
            layer.cornerRadius = 0
        }
        actionButton.layer.cornerRadius = 5
        captionSeparatorView.backgroundColor = theme.colors.border
        captionTextView.textColor = theme.colors.secondaryText
        captionTextView.backgroundColor = .clear
        messageUnderlineColor = isUrgent ? theme.colors.error : nil
        updateCaptionTextViewWithAttributedCaption()
        updateMessageLabelWithAttributedMessage()
    }
}
