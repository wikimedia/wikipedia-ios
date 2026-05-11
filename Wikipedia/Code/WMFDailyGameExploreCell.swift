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

    // MARK: - Subviews

    private let descriptionLabel = UILabel()
    private let playButton = UIButton(type: .system)

    // Event rows — only visible in .notStarted state with events
    private let eventRowA = WMFDailyGameEventRowView()
    private let eventRowB = WMFDailyGameEventRowView()
    private var eventRowsHidden: Bool = true {
        didSet {
            eventRowA.isHidden = eventRowsHidden
            eventRowB.isHidden = eventRowsHidden
        }
    }

    override func setup() {
        super.setup()

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
                descriptionLabel.isHidden = true
                eventRowsHidden = false
                eventRowA.configure(text: optionA.title, thumbnailURL: optionA.thumbnailURL)
                eventRowB.configure(text: optionB.title, thumbnailURL: optionB.thumbnailURL)
            } else {
                descriptionLabel.isHidden = false
                descriptionLabel.text = "Today's history matching game"
                eventRowsHidden = true
            }
            setPlayButtonTitle("Play today's game")
        case .inProgress(let answered, _):
            descriptionLabel.isHidden = false
            descriptionLabel.text = "\(answered) of 5 questions answered"
            eventRowsHidden = true
            setPlayButtonTitle("Continue today's game")
        case .completed(let score, let total):
            descriptionLabel.isHidden = false
            descriptionLabel.text = "Final score: \(score)/\(total)"
            eventRowsHidden = true
            setPlayButtonTitle("Review results")
        }
        setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sessionFetchTask?.cancel()
        sessionFetchTask = nil
        eventRowA.cancelImageLoad()
        eventRowB.cancelImageLoad()
        configure(state: .notStarted(optionA: nil, optionB: nil))
    }

    @objc private func didTapPlayButton() {
        onPlayButtonTapped?()
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
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

        if !eventRowsHidden {
            let rowWidth = availableWidth
            let aFrame = eventRowA.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
            if apply { eventRowA.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: aFrame.height) }
            y += aFrame.height + Self.rowSpacing

            let bFrame = eventRowB.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
            if apply { eventRowB.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: bFrame.height) }
            y += bFrame.height
        } else {
            let descFrame = descriptionLabel.wmf_preferredFrame(
                at: CGPoint(x: layoutMargins.left, y: y),
                maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: apply
            )
            y = descFrame.maxY
        }

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
