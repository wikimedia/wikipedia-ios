import UIKit
import WMFComponents

/// Simple Explore card cell for the "Which Came First?" daily game.
/// Intentionally minimal — this is the entry-point stub before full UI is built.
class WMFDailyGameExploreCell: CollectionViewCell {

    var onPlayButtonTapped: (() -> Void)?

    private let descriptionLabel: UILabel = UILabel()
    private let playButton: UIButton = UIButton(type: .system)

    override func setup() {
        super.setup()

        descriptionLabel.text = "Today's history matching game"
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        addSubview(descriptionLabel)

        playButton.setTitle("Play today's game", for: .normal)
        playButton.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
        addSubview(playButton)
    }

    @objc private func didTapPlayButton() {
        onPlayButtonTapped?()
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        descriptionLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        playButton.titleLabel?.font = WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)
    }

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        layoutMarginsAdditions = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        let layoutMargins = calculatedLayoutMargins
        let availableWidth = size.width - layoutMargins.left - layoutMargins.right

        let descOrigin = CGPoint(x: layoutMargins.left, y: layoutMargins.top)
        let descFrame = descriptionLabel.wmf_preferredFrame(
            at: descOrigin,
            maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
            minimumSize: NoIntrinsicSize,
            alignedBy: .forceLeftToRight,
            apply: apply
        )

        let buttonSpacing: CGFloat = 12
        let buttonOrigin = CGPoint(x: layoutMargins.left, y: descFrame.maxY + buttonSpacing)
        let buttonFrame = playButton.wmf_preferredFrame(
            at: buttonOrigin,
            maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
            minimumSize: NoIntrinsicSize,
            alignedBy: .forceLeftToRight,
            apply: apply
        )

        return CGSize(width: size.width, height: buttonFrame.maxY + layoutMargins.bottom)
    }
}

extension WMFDailyGameExploreCell: Themeable {
    func apply(theme: Theme) {
        descriptionLabel.textColor = theme.colors.secondaryText
        playButton.tintColor = theme.colors.link
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        backgroundView?.backgroundColor = theme.colors.paperBackground
    }
}
