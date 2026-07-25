import UIKit
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Explore card cell for the "Which Came First?" daily game.
class WMFDailyGameExploreCell: CollectionViewCell {

    enum SessionState {
        case notStarted(optionA: WMFWhichCameFirstEvent?, optionB: WMFWhichCameFirstEvent?)
        case inProgress(questionsAnswered: Int, score: Int)
        case completed(score: Int, totalQuestions: Int)
    }

    var tappedPlayTodaysGame: (() -> Void)?
    var tappedContinueTodaysGame: (() -> Void)?
    var tappedReviewResults: (() -> Void)?
    var tappedPlayTheArchive: (() -> Void)?
    var sessionFetchTask: Task<Void, Never>?

    // Countdown timer for the completed state.
    private var countdownTimer: Timer?
    private var completedScore: Int = 0
    private var completedTotal: Int = 0

    private var headerStacked: Bool = false
    
    var isContentRTL: Bool = false {
        didSet {
            eventRowA.isRTL = isContentRTL
            eventRowB.isRTL = isContentRTL
        }
    }
    
    var isChromeRTL: Bool {
        return UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft
    }

    // MARK: - Subviews

    private let headerIconView = UIImageView()
    private let headerTitleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let button1 = UIButton(type: .system)
    private let button2 = UIButton(type: .system)

    // Event rows — shown (possibly transparent) when event data is available
    private let eventRowA = WMFDailyGameEventRowView()
    private let eventRowB = WMFDailyGameEventRowView()
    
    private var lastBottomButtonFrame: CGRect = .zero
    private var lastState: SessionState?

    override func setup() {
        super.setup()

        headerIconView.image = WMFSFSymbolIcon.for(symbol: .calendar)
        headerIconView.contentMode = .scaleAspectFit
        addSubview(headerIconView)

        headerTitleLabel.text = WMFLocalizedString("games-wcf-explore-title", value:"Which came first?", comment: "Title on Which Came First card in the Explore tab.")
        headerTitleLabel.numberOfLines = 1
        headerTitleLabel.lineBreakMode = .byTruncatingTail
        addSubview(headerTitleLabel)

        descriptionLabel.numberOfLines = 3
        descriptionLabel.lineBreakMode = .byTruncatingTail
        descriptionLabel.textAlignment = .natural
        addSubview(descriptionLabel)

        addSubview(eventRowA)
        addSubview(eventRowB)

        button1.addTarget(self, action: #selector(didTapButton1), for: .touchUpInside)
        button1.titleLabel?.numberOfLines = 1
        button1.titleLabel?.lineBreakMode = .byTruncatingTail
        addSubview(button1)

        button2.addTarget(self, action: #selector(didTapButton2), for: .touchUpInside)
        button2.titleLabel?.numberOfLines = 1
        button2.titleLabel?.lineBreakMode = .byTruncatingTail
        addSubview(button2)

        configure(state: .notStarted(optionA: nil, optionB: nil), theme: nil)
    }
    
    private var buttonTraitCollection: UITraitCollection {
        // maxing this out as there's not enough room for the largest type sizes
        let current = UITraitCollection.current
        let preferredSize = current.preferredContentSizeCategory
        if preferredSize > .extraExtraExtraLarge {
            return UITraitCollection(preferredContentSizeCategory: .extraExtraExtraLarge)
        }
        
        return current
    }

    func configure(state: SessionState, theme: Theme?) {
        switch state {
        case .notStarted(let optionA, let optionB):
            headerIconView.image = WMFSFSymbolIcon.for(symbol: .calendar)
            if let optionA, let optionB {
                descriptionLabel.isHidden = true
                eventRowA.isHidden = false
                eventRowA.configure(text: optionA.title, thumbnailURL: optionA.thumbnailURL)
                eventRowB.isHidden = false
                eventRowB.configure(text: optionB.title, thumbnailURL: optionB.thumbnailURL)
            } else {
                descriptionLabel.isHidden = false
                eventRowA.isHidden = true
                eventRowB.isHidden = true
            }
            stopCountdownTimer()
            setButton1Title(CommonStrings.playTodaysGameTitle)
            button2.isHidden = true
            headerStacked = false
        case .inProgress(let answered, _):
            headerIconView.image = WMFSFSymbolIcon.for(symbol: .calendarExclamation)
            descriptionLabel.isHidden = false
            eventRowA.isHidden = true
            eventRowB.isHidden = true
            let descriptionText = WMFLocalizedString("games-wcf-explore-in-progress-subtitle", value:"You're on question %1$d. Continue guessing which event came first on this day in history.", comment: "Description text on Which Came First card in the Explore tab, shown when a game is in progress. %1$d is replaced by which question the user left off of.")
            descriptionLabel.text = String.localizedStringWithFormat(descriptionText, answered + 1)
            stopCountdownTimer()
            setButton1Title(CommonStrings.continueGameTitle)
            button2.isHidden = true
            headerStacked = true
        case .completed(let score, let total):
            headerIconView.image = WMFSFSymbolIcon.for(symbol: .calendarCheckmark)
            descriptionLabel.isHidden = false
            eventRowA.isHidden = true
            eventRowB.isHidden = true
            completedScore = score
            completedTotal = total
            setButton1Title(WMFLocalizedString("games-wcf-explore-button-review-title", value:"Review results", comment: "Button text on Which Came First card in the Explore tab, shown when game is complete. Tapping navigates to the results of the game."))
            setButton2Title(CommonStrings.playTheArchiveTitle)
            button2.isHidden = false
            headerStacked = true
            startCountdownTimer()
        }
        self.lastState = state
        if let theme {
            apply(theme: theme)
        }
        setNeedsLayout()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        sessionFetchTask?.cancel()
        sessionFetchTask = nil
        stopCountdownTimer()
        eventRowA.cancelImageLoad()
        eventRowB.cancelImageLoad()
        configure(state: .notStarted(optionA: nil, optionB: nil), theme: nil)
    }

    @objc private func didTapButton1() {
        guard let lastState else { return }
        switch lastState {
        case .notStarted:
            tappedPlayTodaysGame?()
        case .inProgress:
            tappedContinueTodaysGame?()
        case .completed:
            tappedReviewResults?()
        }
    }

    @objc private func didTapButton2() {
        tappedPlayTheArchive?()
    }

    // MARK: - Countdown Timer

    private func startCountdownTimer() {
        countdownTimer?.invalidate()
        updateCountdownLabel()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.updateCountdownLabel()
        }
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func updateCountdownLabel() {
        let descriptionText = WMFLocalizedString("games-wcf-explore-complete-subtitle", value:"You scored %1$d/%2$d on today's game. Next game in %3$@", comment: "Description text on Which Came First card in the Explore tab, shown when a game is completed. %1$d is replaced by the number of questions answered correctly, %2$d is replaced by the number of total questions. %3$@ is replaced by a countdown timer string, indicating the number of hours / minutes / seconds left until the next game is available.")
        descriptionLabel.text = String.localizedStringWithFormat(descriptionText, completedScore, completedTotal, countdownString())
    }

    private func countdownString() -> String {
        let now = Date()
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now)) else { return "--:--:--" }
        let seconds = max(0, Int(tomorrow.timeIntervalSince(now)))
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    @objc private func appDidBecomeActive() {
        if countdownTimer == nil, case .completed = lastState {
            startCountdownTimer()
        }
    }

    @objc private func appWillResignActive() {
        stopCountdownTimer()
    }

    override func updateFonts(with traitCollection: UITraitCollection) {
        super.updateFonts(with: traitCollection)
        headerTitleLabel.font = WMFFont.for(.boldSubheadline, compatibleWith: traitCollection)
        descriptionLabel.font = WMFFont.for(.subheadline, compatibleWith: traitCollection)
        button1.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: buttonTraitCollection)
        button2.titleLabel?.font = WMFFont.for(.mediumSubheadline, compatibleWith: buttonTraitCollection)
        eventRowA.updateFonts(with: traitCollection)
        eventRowB.updateFonts(with: traitCollection)
    }

    // MARK: - Layout

    private static let eventRowSpacing: CGFloat = 16
    private static let cardBottomPadding: CGFloat = 20

    override func sizeThatFits(_ size: CGSize, apply: Bool) -> CGSize {
        layoutMarginsAdditions = UIEdgeInsets(top: 12, left: 1, bottom: 12, right: 1)
        let layoutMargins = calculatedLayoutMargins
        let availableWidth = size.width - layoutMargins.left - layoutMargins.right

        var y = layoutMargins.top

        if headerStacked {
            let iconSize: CGFloat = CGFloat(37)
            if apply {
                headerIconView.frame = CGRect(x: isChromeRTL ? size.width - layoutMargins.right - iconSize : layoutMargins.left, y: y, width: iconSize, height: iconSize)
            }
            y += iconSize + 15
            let headerTitleFrame = headerTitleLabel.wmf_preferredFrame(
                at: CGPoint(x: layoutMargins.left, y: y),
                maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: false
            )
            
            if apply {
                if isChromeRTL {
                    headerTitleLabel.frame = CGRect(x: size.width - layoutMargins.right - headerTitleFrame.width, y: headerTitleFrame.minY, width: headerTitleFrame.width, height: headerTitleFrame.height)
                } else {
                    headerTitleLabel.frame = headerTitleFrame
                }
            }
            y = headerTitleFrame.maxY + 5
        } else {
            let iconSize: CGFloat = CGFloat(22)
            let iconXOffset = CGFloat(-2)
            
            let headerTitleXOffset = CGFloat(5)
            let headerTitleFrame = headerTitleLabel.wmf_preferredFrame(
                at: CGPoint(x: layoutMargins.left + iconSize + headerTitleXOffset, y: y),
                maximumSize: CGSize(width: availableWidth - iconSize - headerTitleXOffset, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: false
            )
            
            let centeredOffset = (headerTitleFrame.height - iconSize) / 2
            
            let headerIconFrame = CGRect(x: layoutMargins.left + iconXOffset, y: y + centeredOffset, width: iconSize, height: iconSize)
            
            if apply {
                if isChromeRTL {
                    headerIconView.frame = CGRect(x: (size.width - layoutMargins.right - iconSize) + iconXOffset, y: headerIconFrame.minY, width: headerIconFrame.width, height: headerIconFrame.height)
                    headerTitleLabel.frame = CGRect(x: headerIconView.frame.minX - headerTitleXOffset - headerTitleFrame.width, y: headerTitleFrame.minY, width: headerTitleFrame.width, height: headerTitleFrame.height)
                } else {
                    headerIconView.frame = headerIconFrame
                    headerTitleLabel.frame = headerTitleFrame
                }
                
            }
            
            y = headerTitleFrame.maxY + 12
        }
        
        // Gap between the content above and the primary button. Consistent across every state so
        // the button stays comfortably padded no matter how tall the event rows grow (e.g. three
        // lines of text per event) or how long the description is.
        let button1Spacing: CGFloat = layoutMargins.bottom
        if !descriptionLabel.isHidden {
            let descriptionFrame = descriptionLabel.wmf_preferredFrame(
                at: CGPoint(x: layoutMargins.left, y: y),
                maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: false
            )

            if apply {
                if isChromeRTL {
                    descriptionLabel.frame = CGRect(x: size.width - layoutMargins.right - descriptionFrame.width, y: descriptionFrame.minY, width: descriptionFrame.width, height: descriptionFrame.height)
                } else {
                    descriptionLabel.frame = descriptionFrame
                }
            }

            y += descriptionFrame.height
        } else {
            let rowWidth = availableWidth
            let aFrame = eventRowA.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
            if apply { eventRowA.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: aFrame.height) }
            y += aFrame.height + Self.eventRowSpacing

            let bFrame = eventRowB.sizeThatFits(CGSize(width: rowWidth, height: UIView.noIntrinsicMetric))
            if apply { eventRowB.frame = CGRect(x: layoutMargins.left, y: y, width: rowWidth, height: bFrame.height) }
            y += bFrame.height
        }

        let button1Frame = button1.wmf_preferredFrame(
            at: CGPoint(x: layoutMargins.left, y: y + button1Spacing),
            maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
            minimumSize: NoIntrinsicSize,
            alignedBy: .forceLeftToRight,
            apply: false
        )
        if apply {
            if isChromeRTL {
                button1.frame = CGRect(x: size.width - layoutMargins.right - button1Frame.width, y: button1Frame.minY, width: button1Frame.width, height: button1Frame.height)
            } else {
                button1.frame = button1Frame
            }
        }
    
        y += button1Spacing + button1Frame.height

        if !button2.isHidden {
            
            let button2HorizontalSpacing = CGFloat(24)
            let button2VerticalSpacing = CGFloat(10)
            
            let button2Frame = button2.wmf_preferredFrame(
                at: CGPoint(x: button1Frame.minX, y: button1Frame.minY),
                maximumSize: CGSize(width: availableWidth, height: UIView.noIntrinsicMetric),
                minimumSize: NoIntrinsicSize,
                alignedBy: .forceLeftToRight,
                apply: false
            )
            
            // if they won't fit, display stacked.
            if button1Frame.width + button2Frame.width + button2HorizontalSpacing > availableWidth {
                
                if apply {
                    if isChromeRTL {
                        button2.frame = CGRect(x: size.width - layoutMargins.right - button2Frame.width, y: button1Frame.maxY + button2VerticalSpacing, width: button2Frame.width, height: button2Frame.height)
                    } else {
                        button2.frame = CGRect(x: layoutMargins.left, y: button1Frame.maxY + button2VerticalSpacing, width: button2Frame.width, height: button2Frame.height)
                    }
                }
                
                y += button2VerticalSpacing + button2Frame.height
            } else { // display horizontally
                if apply {
                    if isChromeRTL {
                        button2.frame = CGRect(x: size.width - layoutMargins.right - button1Frame.width - button2HorizontalSpacing - button2Frame.width, y: button1Frame.minY, width: button2Frame.width, height: button2Frame.height)
                    } else {
                        button2.frame = CGRect(x: button1Frame.maxX + button2HorizontalSpacing, y: button1Frame.minY, width: button2Frame.width, height: button2Frame.height)
                    }
                }
            }
        }

        return CGSize(width: size.width, height: y + Self.cardBottomPadding)
    }
    
    /// UIButton defers flushing `setTitle(_:for:)` to `titleLabel.text` until its own
    /// layout pass, which happens after `sizeThatFits` measures the label. Setting
    /// `titleLabel?.text` directly ensures the manual layout sizing pass sees the new value.
    private func setButton1Title(_ title: String) {
        button1.setTitle(title, for: .normal)
        button1.titleLabel?.text = title
    }
    
    private func setButton2Title(_ title: String) {
        button2.setTitle(title, for: .normal)
        button2.titleLabel?.text = title
    }
}

extension WMFDailyGameExploreCell: Themeable {
    func apply(theme: Theme) {
        
        headerTitleLabel.textColor = theme.colors.primaryText
        descriptionLabel.textColor = theme.colors.secondaryText
        button1.tintColor = theme.colors.link
        button2.tintColor = theme.colors.link
        eventRowA.apply(theme: theme)
        eventRowB.apply(theme: theme)
        if let lastState {
            switch lastState {
            case .notStarted(let optionA, let optionB):
                headerIconView.tintColor = theme.colors.primaryText
            case .inProgress(let questionsAnswered, let score):
                headerIconView.tintColor = theme.colors.link
            case .completed(let score, let totalQuestions):
                headerIconView.tintColor = theme.colors.accent
            }
        }
    }
}

// MARK: - WMFDailyGameEventRowView

/// A single event row: truncated text on the left, small thumbnail on the right.
private final class WMFDailyGameEventRowView: UIView {

    let textLabel = UILabel()
    // let sizingTextLabel = UILabel()
    private let thumbnailView = UIImageView()
    private var imageLoadTask: URLSessionDataTask?

    private static let imageSize = CGSize(width: 40, height: 40)
    private static let imageTextSpacing: CGFloat = 16

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var isRTL: Bool = false {
        didSet {
            textLabel.textAlignment = isRTL ? .right : .natural
            // sizingTextLabel.textAlignment = isRTL ? .right : .natural
        }
    }

    private func setup() {
        textLabel.numberOfLines = 3
        textLabel.lineBreakMode = .byTruncatingTail
        addSubview(textLabel)
        
        thumbnailView.contentMode = .scaleAspectFill
        thumbnailView.clipsToBounds = true
        thumbnailView.layer.cornerRadius = 2
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
        
        textLabel.frame = CGRect(x: isRTL ? imgSize.width + spacing : 0, y: max(0, (bounds.height - textHeight) / 2), width: textWidth, height: textHeight)
        thumbnailView.frame = CGRect(x: isRTL ? 0 : bounds.width - imgSize.width, y: max(0, (bounds.height - imgSize.height) / 2), width: imgSize.width, height: imgSize.height)
    }
}
