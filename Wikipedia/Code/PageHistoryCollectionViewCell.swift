import UIKit

class PageHistoryCollectionViewCell: CollectionViewCell {
    private let roundedContent = UIView()
    private let timeLabel = UILabel()
    private let sizeDiffLabel = UILabel()
    private let minorImageView = UIImageView()
    private let commentLabel = UILabel()
    private let authorButton = AlignedImageButton()

    private let spacing: CGFloat = 3

    var time: String? {
        didSet {
            timeLabel.text = time
            setNeedsLayout()
        }
    }

    var sizeDiff: Int? {
        didSet {
            guard let sizeDiff = sizeDiff else {
                sizeDiffLabel.isHidden = true
                return
            }
            sizeDiffLabel.isHidden = false
            sizeDiffLabel.text = sizeDiff > 0 ? "+\(sizeDiff)" : "\(sizeDiff)"
            setNeedsLayout()
        }
    }

    var authorImage: UIImage? {
        didSet {
            setNeedsLayout()
        }
    }

    var author: String? {
        didSet {
            authorButton.setTitle(author, for: .normal)
            setNeedsLayout()
        }
    }

    var comment: String? {
        didSet {
            setNeedsLayout()
        }
    }

    var isMinor: Bool = false {
        didSet {
            setNeedsLayout()
        }
    }

    override func setup() {
        super.setup()
        roundedContent.layer.cornerRadius = 6
        roundedContent.layer.masksToBounds = true
        roundedContent.layer.borderWidth = 1

        roundedContent.addSubview(timeLabel)
        roundedContent.addSubview(sizeDiffLabel)
        authorButton.horizontalSpacing = 8
        roundedContent.addSubview(authorButton)
        minorImageView.contentMode = .scaleAspectFit
        roundedContent.addSubview(minorImageView)
        commentLabel.numberOfLines = 2
        commentLabel.lineBreakMode = .byTruncatingTail
        roundedContent.addSubview(commentLabel)
        contentView.addSubview(roundedContent)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        timeLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        sizeDiffLabel.font = UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
        authorButton.titleLabel?.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        commentLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    // TODO: Fix RTL
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins

        let widthMinusMargins = layoutWidth(for: size)

        roundedContent.frame = CGRect(x: layoutMargins.left, y: 0, width: widthMinusMargins, height: bounds.height)

        let availableWidth = widthMinusMargins - layoutMargins.left - layoutMargins.right
        let leadingPaneAvailableWidth = availableWidth / 3
        let trailingPaneAvailableWidth = availableWidth - leadingPaneAvailableWidth

        var leadingPaneOrigin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        var trailingPaneOrigin = CGPoint(x: layoutMargins.left + leadingPaneAvailableWidth, y: layoutMargins.top)

        if timeLabel.wmf_hasText {
            let timeLabelFrame = timeLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            leadingPaneOrigin.y += timeLabelFrame.layoutHeight(with: spacing * 2)
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }

        if sizeDiffLabel.wmf_hasText {
            let sizeDiffLabelFrame = sizeDiffLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            leadingPaneOrigin.y += sizeDiffLabelFrame.layoutHeight(with: spacing)
            sizeDiffLabel.isHidden = false
        } else {
            sizeDiffLabel.isHidden = true
        }

        if authorButton.titleLabel?.wmf_hasText ?? false {
            let authorButtonFrame = authorButton.wmf_preferredFrame(at: trailingPaneOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            trailingPaneOrigin.y += authorButtonFrame.layoutHeight(with: spacing * 3)
            authorButton.isHidden = false
        } else {
            authorButton.isHidden = true
        }

        if commentLabel.wmf_hasText {
            let commentLabelFrame = commentLabel.wmf_preferredFrame(at: trailingPaneOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            trailingPaneOrigin.y += commentLabelFrame.layoutHeight(with: spacing)
            commentLabel.isHidden = false
        } else {
            commentLabel.isHidden = true
        }
        return CGSize(width: size.width, height: max(leadingPaneOrigin.y, trailingPaneOrigin.y) + layoutMargins.bottom)
    }
}

extension PageHistoryCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        roundedContent.layer.borderColor = theme.colors.border.cgColor
        roundedContent.backgroundColor = theme.colors.paperBackground
        timeLabel.textColor = theme.colors.secondaryText
        if let sizeDiff = sizeDiff {
            if sizeDiff == 0 {
                sizeDiffLabel.textColor = theme.colors.link
            } else if sizeDiff > 0 {
                sizeDiffLabel.textColor = theme.colors.accent
            } else {
                sizeDiffLabel.textColor = theme.colors.destructive
            }
        }
        authorButton.setTitleColor(theme.colors.link, for: .normal)
    }
}
