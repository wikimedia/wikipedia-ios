import UIKit

class PageHistoryCollectionViewCell: CollectionViewCell {
    private let roundedContent = UIView()
    private let timeLabel = UILabel()
    private let sizeDiffLabel = UILabel()
    private let authorImageView = UIImageView()
    private let authorLabel = UILabel()
    private let minorImageView = UIImageView()
    private let commentLabel = UILabel()

    private let spacing: CGFloat = 3

    var time: String? {
        didSet {
            timeLabel.text = time
            setNeedsLayout()
        }
    }

    var sizeDiff: String? {
        didSet {
            sizeDiffLabel.text = sizeDiff
            setNeedsLayout()
        }
    }

    var authorImage: UIImage? {
        didSet {
            authorImageView.image = authorImage
            setNeedsLayout()
        }
    }

    var author: String? {
        didSet {
            authorLabel.text = author
            setNeedsLayout()
        }
    }

    var comment: String? {
        didSet {
            commentLabel.text = comment
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
        authorImageView.contentMode = .scaleAspectFit
        roundedContent.addSubview(authorImageView)
        roundedContent.addSubview(authorLabel)
        minorImageView.contentMode = .scaleAspectFit
        roundedContent.addSubview(minorImageView)
        commentLabel.numberOfLines = 2
        commentLabel.lineBreakMode = .byTruncatingTail
        roundedContent.addSubview(commentLabel)
        contentView.addSubview(roundedContent)
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        timeLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        sizeDiffLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        authorLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
        commentLabel.font = UIFont.wmf_font(.footnote, compatibleWithTraitCollection: traitCollection)
    }

    // TODO: Fix RTL
    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        let size = super.sizeThatFits(size, apply: apply)
        let layoutMargins = calculatedLayoutMargins

        let widthMinusMargins = layoutWidth(for: size)

        roundedContent.frame = CGRect(x: layoutMargins.left, y: layoutMargins.top, width: widthMinusMargins, height: bounds.height)

        let availableWidth = widthMinusMargins - layoutMargins.left - layoutMargins.right
        let leadingPaneAvailableWidth = availableWidth / 3
        let trailingPaneAvailableWidth = availableWidth - leadingPaneAvailableWidth

        var leadingPaneOrigin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        var trailingPaneOrigin = CGPoint(x: layoutMargins.left + leadingPaneAvailableWidth, y: layoutMargins.top)

        if timeLabel.wmf_hasText {
            let timeLabelFrame = timeLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            leadingPaneOrigin.y += timeLabelFrame.layoutHeight(with: spacing)
        } else {
            // TODO
        }

        if sizeDiffLabel.wmf_hasText {
            let sizeDiffLabelFrame = sizeDiffLabel.wmf_preferredFrame(at: leadingPaneOrigin, maximumWidth: leadingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            leadingPaneOrigin.y += sizeDiffLabelFrame.layoutHeight(with: spacing)
        } else {
            // TODO
        }

        authorImageView.isHidden = authorImageView.image == nil

        if authorImageView.isHidden {
            // TODO
        } else {
            let imageViewDimension: CGFloat = 20
            authorImageView.frame = CGRect(x: trailingPaneOrigin.x, y: trailingPaneOrigin.y, width: imageViewDimension, height: imageViewDimension)

            if authorLabel.wmf_hasText {
                let authorLabelFrameOrigin = CGPoint(x: authorImageView.frame.maxX + spacing * 3, y: trailingPaneOrigin.y)
                let authorLabelFrame = authorLabel.wmf_preferredFrame(at: authorLabelFrameOrigin, maximumWidth: trailingPaneAvailableWidth - imageViewDimension, alignedBy: .forceLeftToRight, apply: apply)
                trailingPaneOrigin.y += max(imageViewDimension + spacing * 2, authorLabelFrame.layoutHeight(with: spacing * 2))
            } else {
                // TODO
            }
        }

        if commentLabel.wmf_hasText {
            let commentLabelFrame = commentLabel.wmf_preferredFrame(at: trailingPaneOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
            trailingPaneOrigin.y += commentLabelFrame.layoutHeight(with: spacing)
        } else {
            // TODO
        }
        return CGSize(width: size.width, height: max(leadingPaneOrigin.y, trailingPaneOrigin.y) + layoutMargins.bottom)
    }
}

extension PageHistoryCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        roundedContent.layer.borderColor = theme.colors.border.cgColor
        roundedContent.backgroundColor = theme.colors.paperBackground
    }
}
