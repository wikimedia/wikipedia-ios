import UIKit
import WMFComponents
import WMFData

/// Explore card cell for the "Which Came First?" daily game.
class WMFDailyGameExploreCell: CollectionViewCell {

    enum SessionState {
        case notStarted(optionA: WMFWhichCameFirstEvent?, optionB: WMFWhichCameFirstEvent?)
        case inProgress(questionsAnswered: Int, score: Int)
        case completed(score: Int, totalQuestions: Int)
    }

    var onPlayButtonTapped: (() -> Void)?
    var sessionFetchTask: Task<Void, Never>?

    // Persisted so inProgress can still lay out invisible event rows at the correct size.
    private var cachedEventA: WMFWhichCameFirstEvent?
    private var cachedEventB: WMFWhichCameFirstEvent?

    // MARK: - Subviews

    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let playButton = UIButton(type: .system)

    // Event rows — shown (possibly transparent) when event data is available
    private let eventRowA = WMFDailyGameEventRowView()
    private let eventRowB = WMFDailyGameEventRowView()

    /// When true the rows still occupy space but are invisible (alpha = 0).
    private var eventRowsTransparent: Bool = false {
        didSet {
            let a: CGFloat = eventRowsTransparent ? 0 : 1
            eventRowA.alpha = a
            eventRowB.alpha = a
        }
    }

    override func setup() {
        super.setup()

        headerIconView.image = WMFSFSymbolIcon.for(symbol: .calendar)
        headerIconView.contentMode = .scaleAspectFit
        addSubview(headerIconView)

        headerTitleLabel.text = "Which came first?"
        headerTitleLabel.numberOfLines = 1
        addSubview(headerTitleLabel)

        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .left
        addSubview(descriptionLabel)

        addSubview(eventRowA)
        addSubview(eventRowB)

        playButton.addTarget(self, action: #selector(didTapPlayButton), for: .touchUpInside)
        addSubview(playButton)

        configure(state: .notStarted(optionA: nil, optionB: nil))
    }

    func configure(state: SessionState) {
        switch state {
        case .notStarted(let optionA, let optionB):
            if let optionA, let optionB {
                cachedEventA = optionA
                cachedEventB = optionB
                descriptionLabel.isHidden = true
                eventRowsTransparent = false
                eventRowA.configure(text: optionA.title, thumbnailURL: optionA.thumbnailURL)
                eventRowB.configure(text: optionB.title, thumbnailURL: optionB.thumbnailURL)
            } else {
                eventRowsTransparent = false
            }
            setPlayButtonTitle("Play today's game")
        case .inProgress(let answered, _):
            descriptionLabel.isHidden = false
            descriptionLabel.text = "You're on question \(answered + 1). Continue guessing which event came first on this day in history."
            // Keep event rows in layout (invisible) so the button stays anchored at the same position.
            if let a = cachedEventA, let b = cachedEventB {
                eventRowA.configure(text: a.title, thumbnailURL: a.thumbnailURL)
                eventRowB.configure(text: b.title, thumbnailURL: b.thumbnailURL)
                eventRowsTransparent = true
            } else {
                eventRowsTransparent = true
            }
            setPlayButtonTitle("Continue today's game")
        case .completed(let score, let total):
            descriptionLabel.isHidden = false
            descriptionLabel.text = "Final score: \(score)/\(total)"
            eventRowsTransparent = false
            setPlayButtonTitle("Review results")
        }
        setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sessionFetchTask?.cancel()
        sessionFetchTask = nil
        cachedEventA = nil
        cachedEventB = nil
        eventRowA.cancelImageLoad()
        eventRowB.cancelImageLoad()
        configure(state: .notStarted(optionA: nil, optionB: nil))
    }

    @objc private func didTapPlayButton() {
        onPlayButtonTapped?()
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        headerTitleLabel.font = WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)
        descriptionLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        playButton.titleLabel?.font = WMFFont.for(.semiboldSubheadline, compatibleWith: traitCollection)
        eventRowA.updateFonts(with: traitCollection)
        eventRowB.updateFonts(with: traitCollection)
    }

    // MARK: - Layout

    private static let imageSize = CGSize(width: 44, height: 44)
    private static let rowSpacing: CGFloat = 12
    private static let imageTextSpacing: CGFloat = 12

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        layoutMarginsAdditions = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        let layoutMargins = calculatedLayoutMargins
        let availableWidth = size.width - layoutMargins.left - layoutMargins.right

        var y = layoutMargins.top

        // Header: calendar icon on its own line, then title below
        let iconSize: CGFloat = 22
        if apply {
            headerIconView.frame = CGRect(x: layoutMargins.left, y: y, width: iconSize, height: iconSize)
        }
        y += iconSize + 6
        let headerTitleFrame = headerTitleLabel.wmf_preferredFrame(
            at: CGPoint(x: layoutMargins.left, y: y),
            maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
            minimumSize: NoIntrinsicSize,
            alignedBy: .forceLeftToRight,
            apply: apply
        )
        y = headerTitleFrame.maxY + 12
        
        if !descriptionLabel.isHidden {
            let _ = descriptionLabel.wmf_preferredFrame(
                at: CGPoint(x: layoutMargins.left, y: y),
                maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: apply
            )
        }

        let rowWidth = availableWidth
        let aFrame = eventRowA.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
        if apply { eventRowA.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: aFrame.height) }
        y += aFrame.height + Self.rowSpacing

        let bFrame = eventRowB.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
        if apply { eventRowB.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: bFrame.height) }
        y += bFrame.height

        let buttonSpacing: CGFloat = 12
        let buttonFrame = playButton.wmf_preferredFrame(
            at: CGPoint(x: layoutMargins.left, y: y + buttonSpacing),
            maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
            minimumSize: NoIntrinsicSize,
            alignedBy: .forceLeftToRight,
            apply: apply
        )

        return CGSize(width: size.width, height: buttonFrame.maxY + layoutMargins.bottom)
    }
    
    /// UIButton defers flushing `setTitle(_:for:)` to `titleLabel.text` until its own
    /// layout pass, which happens after `sizeThatFits` measures the label. Setting
    /// `titleLabel?.text` directly ensures the manual layout sizing pass sees the new value.
    private func setPlayButtonTitle(_ title: String) {
        playButton.setTitle(title, for: .normal)
        playButton.titleLabel?.text = title
    }
}

extension WMFDailyGameExploreCell: Themeable {
    func apply(theme: Theme) {
        headerIconView.tintColor = theme.colors.primaryText
        headerTitleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        playButton.tintColor = theme.colors.link
        selectedBackgroundView?.backgroundColor = theme.colors.midBackground
        backgroundView?.backgroundColor = theme.colors.paperBackground
        eventRowA.apply(theme: theme)
        eventRowB.apply(theme: theme)
    }
}

// MARK: - WMFDailyGameEventRowView

/// A single event row: truncated text on the left, small thumbnail on the right.
private final class WMFDailyGameEventRowView: UIView {

    private let textLabel = UILabel()
    private let thumbnailView = UIImageView()
    private var imageLoadTask: URLSessionDataTask?

    private static let imageSize = CGSize(width: 44, height: 44)
    private static let imageTextSpacing: CGFloat = 12

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        textLabel.numberOfLines = 3
        textLabel.lineBreakMode = .byTruncatingTail
        addSubview(textLabel)

        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 4
        thumbnailView.backgroundColor = .clear
        addSubview(thumbnailView)
    }

    func configure(text: String, thumbnailURL: URL?) {
        textLabel.text = text
        thumbnailView.image = nil
        imageLoadTask?.cancel()
        imageLoadTask = nil

        if let url = thumbnailURL {
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async { self?.thumbnailView.image = image }
            }
            imageLoadTask = task
            task.resume()
        }
    }

    func cancelImageLoad() {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        thumbnailView.image = nil
    }

    func updateFonts(with traitCollection: UITraitCollection) {
        textLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
    }

    func apply(theme: Theme) {
        textLabel.textColor = theme.colors.primaryText
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let imgSize = WMFDailyGameEventRowView.imageSize
        let spacing = WMFDailyGameEventRowView.imageTextSpacing
        let textWidth = size.width - imgSize.width - spacing
        let textHeight = textLabel.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        let height = max(textHeight, imgSize.height)
        return CGSize(width: size.width, height: height)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let imgSize = WMFDailyGameEventRowView.imageSize
        let spacing = WMFDailyGameEventRowView.imageTextSpacing
        let textWidth = bounds.width - imgSize.width - spacing
        let textHeight = textLabel.sizeThatFits(CGSize(width: textWidth, height: .greatestFiniteMagnitude)).height
        textLabel.frame = CGRect(x: 0, y: max(0, (bounds.height - textHeight) / 2), width: textWidth, height: textHeight)
        thumbnailView.frame = CGRect(x: bounds.width - imgSize.width, y: max(0, (bounds.height - imgSize.height) / 2), width: imgSize.width, height: imgSize.height)
    }
}
