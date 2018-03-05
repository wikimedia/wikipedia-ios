import UIKit

@objc(WMFAnnouncementCollectionViewCellDelegate)
protocol AnnouncementCollectionViewCellDelegate: NSObjectProtocol {
    func announcementCellDidTapDismiss(_ cell: AnnouncementCollectionViewCell)
    func announcementCellDidTapActionButton(_ cell: AnnouncementCollectionViewCell)
    @objc(announcementCell:didTapLinkURL:)
    func announcementCell(_ cell: AnnouncementCollectionViewCell, didTapLinkURL: URL)
}

@objc(WMFAnnouncementCollectionViewCell)
open class AnnouncementCollectionViewCell: CollectionViewCell {
    @objc var delegate: AnnouncementCollectionViewCellDelegate?
    
    @objc public let imageView = UIImageView()
    @objc public let messageLabel = UILabel()
    @objc public let actionButton = UIButton()
    @objc public let dismissButton = UIButton()
    @objc public let captionTextView = UITextView()
    @objc public let captionSeparatorView = UIView()
    public let messageSpacing: CGFloat = 20
    public let buttonMargin: CGFloat = 40
    public let actionButtonHeight: CGFloat = 40
    public let dismissButtonSpacing: CGFloat = 8
    public let dismissButtonHeight: CGFloat = 32
    @objc public var imageViewDimension: CGFloat = 150
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
        
        actionButton.titleEdgeInsets = UIEdgeInsets.init(top: 0, left: 6, bottom: 0, right: 6)
        
        actionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        dismissButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        dismissButton.setTitle(CommonStrings.dismissButtonTitle, for: .normal)
        actionButton.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
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
        caption = nil
        messageLabel.text = nil
        isImageViewHidden = true
    }
    
    open override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        messageLabel.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .subheadline, compatibleWithTraitCollection: traitCollection)
        actionButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .body, compatibleWithTraitCollection: traitCollection)
        dismissButton.titleLabel?.font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection)
        updateCaptionTextViewWithAttributedCaption()
    }
    
    @objc var isImageViewHidden = false {
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
        guard let text = caption else {
            isCaptionHidden = true
            return
        }

        let mutableText = NSMutableAttributedString(attributedString: text)
        guard mutableText.length > 0 else {
            isCaptionHidden = true
            return
        }

        let pStyle = NSMutableParagraphStyle()
        pStyle.lineBreakMode = .byWordWrapping
        pStyle.baseWritingDirection = .natural
        pStyle.alignment = .center
        let font = UIFont.wmf_preferredFontForFontFamily(.system, withTextStyle: .footnote, compatibleWithTraitCollection: traitCollection) ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let color = captionTextView.textColor ?? UIColor.black
        let attributes: [NSAttributedStringKey : Any] = [NSAttributedStringKey.paragraphStyle: pStyle, NSAttributedStringKey.font: font, NSAttributedStringKey.foregroundColor: color]
        mutableText.addAttributes(attributes, range: NSMakeRange(0, mutableText.length))
        captionTextView.attributedText = mutableText

        isCaptionHidden = false
    }

    @objc var caption: NSAttributedString? {
        didSet {
            updateCaptionTextViewWithAttributedCaption()
        }
    }
    
    open override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let widthMinusMargins = size.width - layoutMargins.left - layoutMargins.right
        let displayScale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 2.0
        var origin = CGPoint(x: layoutMargins.left, y: 0)
        
        if !isImageViewHidden {
            if (apply) {
                imageView.frame = CGRect(x: 0, y: 0, width: size.width, height: imageViewDimension)
            }
            origin.y += imageViewDimension
        }
        
        origin.y += messageSpacing
        
        let messageFrame = messageLabel.wmf_preferredFrame(at: origin, fitting: widthMinusMargins, alignedBy: semanticContentAttribute, apply: apply)
        origin.y += messageFrame.layoutHeight(with: messageSpacing)
        
        
        let actionButtonFrame = CGRect(x: buttonMargin, y: origin.y, width: size.width - 2*buttonMargin, height: actionButtonHeight)
        if (apply) {
            actionButton.frame = actionButtonFrame
        }
        origin.y += actionButtonFrame.layoutHeight(with: dismissButtonSpacing)
        
        let dismissButtonFrame = CGRect(x: buttonMargin, y: origin.y, width: size.width - 2*buttonMargin, height: dismissButtonHeight)
        if (apply) {
            dismissButton.frame = dismissButtonFrame
        }
        origin.y += dismissButtonFrame.layoutHeight(with: 0)
        
        if !isCaptionHidden {
            origin.y += dismissButtonSpacing
            let separatorFrame = CGRect(x: 0, y: origin.y, width: size.width, height: 1.0 / displayScale)
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
        setBackgroundColors(theme.colors.paperBackground, selected: theme.colors.midBackground)
        messageLabel.textColor = theme.colors.primaryText
        dismissButton.setTitleColor(theme.colors.secondaryText, for: .normal)
        imageView.backgroundColor = theme.colors.midBackground
        imageView.alpha = theme.imageOpacity
        actionButton.setTitleColor(theme.colors.link, for: .normal)
        actionButton.layer.borderColor = theme.colors.link.cgColor
        actionButton.layer.borderWidth = 1
        actionButton.layer.cornerRadius = 5
        captionSeparatorView.backgroundColor = theme.colors.border
        captionTextView.textColor = theme.colors.secondaryText
        captionTextView.backgroundColor = theme.colors.paperBackground
        updateCaptionTextViewWithAttributedCaption()
    }
}
