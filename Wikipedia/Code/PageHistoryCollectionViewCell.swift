import UIKit

class PageHistoryCollectionViewCell: CollectionViewCell {
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

    override func setup() {
        super.setup()
        layer.cornerRadius = 6
        layer.masksToBounds = true
        layer.borderWidth = 1

        contentView.addSubview(timeLabel)
        contentView.addSubview(sizeDiffLabel)
        authorImageView.contentMode = .scaleAspectFit
        contentView.addSubview(authorImageView)
        contentView.addSubview(authorLabel)
        minorImageView.contentMode = .scaleAspectFit
        contentView.addSubview(minorImageView)
        contentView.addSubview(commentLabel)
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
        let leadingPaneAvailableWidth = widthMinusMargins / 3
        let trailingPaneAvailableWidth = widthMinusMargins - leadingPaneAvailableWidth

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
                let authorLabelFrameOrigin = CGPoint(x: authorImageView.frame.maxX + spacing * 4, y: trailingPaneOrigin.y)
                let authorLabelFrame = authorLabel.wmf_preferredFrame(at: authorLabelFrameOrigin, maximumWidth: trailingPaneAvailableWidth, alignedBy: .forceLeftToRight, apply: apply)
                trailingPaneOrigin.y += max(imageViewDimension + spacing, authorLabelFrame.layoutHeight(with: spacing))
            } else {
                // TODO
            }

            trailingPaneOrigin.y += authorImageView.frame.layoutHeight(with: spacing)
        }

        return CGSize(width: size.width, height: max(leadingPaneOrigin.y, trailingPaneOrigin.y))
    }
}

extension PageHistoryCollectionViewCell: Themeable {
    func apply(theme: Theme) {
        layer.borderColor = theme.colors.border.cgColor
    }
}
