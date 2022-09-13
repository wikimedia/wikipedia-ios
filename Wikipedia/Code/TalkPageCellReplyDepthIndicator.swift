import UIKit
import WMF

final class TalkPageCellReplyDepthIndicator: SetupView {

    // MARK: - Properties

    var depth: Int

    private let stickWidth: CGFloat = 1
    private let stickHorizontalSpacing: CGFloat = 6
    private let stickHeightDelta: CGFloat = 8

    fileprivate var theme: Theme = .light

    // MARK: - UI Elements

    lazy var stickContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    lazy var depthLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        return label
    }()

    // MARK: - Lifecycle

    required init(depth: Int) {
        self.depth = depth
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func setup() {
        setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .horizontal)

        addSubview(stickContainer)

        NSLayoutConstraint.activate([
            stickContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickContainer.topAnchor.constraint(equalTo: topAnchor),
            stickContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override var intrinsicContentSize: CGSize {
        return calculateIntrinsicContentSize()
    }

    private func calculateIntrinsicContentSize() -> CGSize {
        return CGSize(width: requiredTotalStickWidth, height: UIView.noIntrinsicMetric)
    }

    private var requiredTotalStickWidth: CGFloat {
        guard depth > 0 else {
            return 0
        }
        
        return stickWidth * CGFloat(depth) + stickHorizontalSpacing * CGFloat(depth)
    }

    private var requiredMaximumStickHeight: CGFloat {
        return stickHeightDelta * CGFloat(depth)
    }

//    private var totalDrawableSticksGivenCurrentFrame: Int {
//        let drawableSticksConsideringWidthOnly = Int(frame.width / (stickWidth + stickHorizontalSpacing))
//        let drawableSticksConsideringHeightOnly = Int(frame.height / stickHeightDelta)
//        let drawableSticksConsideringHeightAndSpacing = drawableSticksConsideringHeightOnly - Int((stickWidth + stickHorizontalSpacing) * CGFloat(depth))
//
//        // TODO: - this is wrong
//        return min(drawableSticksConsideringWidthOnly, drawableSticksConsideringHeightOnly)
//    }


    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateIntrinsicContentSize()

        let availableHeight = frame.height
        let availableWidth = frame.width

        stickContainer.subviews.forEach { $0.removeFromSuperview() }
        depthLabel.removeFromSuperview()
        
        guard depth > 0 else {
            return
        }

        let drawableSticks = Int(availableWidth / (stickWidth + stickHorizontalSpacing))
        var drawnCount = 0
        
        guard drawableSticks >= 1 else {
            return
        }

        for lineDepth in 1...drawableSticks {
            let height = availableHeight - stickHeightDelta * CGFloat(lineDepth)
            guard height > 0 else {
                break
            }
            let line = UIView(frame: CGRect(x: availableWidth - CGFloat(lineDepth) * (stickHorizontalSpacing + stickWidth), y: 0, width: stickWidth, height: height))
            line.backgroundColor = theme.colors.depthMarker
            stickContainer.addSubview(line)
            drawnCount += 1
        }

        if drawnCount < depth {
            addSubview(depthLabel)
            depthLabel.text = "+\(depth-drawnCount)"
            depthLabel.sizeToFit()
            depthLabel.textColor = theme.colors.depthMarker

            var intersectingViews = 0

            for line in stickContainer.subviews {
                if line.frame.intersects(depthLabel.convert(depthLabel.frame, to: line)) {
                    intersectingViews += 1
                    line.removeFromSuperview()
                }
            }

            depthLabel.text = "+\(depth-drawnCount + intersectingViews)"
        }

    }

    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        depth = viewModel.replyDepth
    }

}

extension TalkPageCellReplyDepthIndicator: Themeable {

    func apply(theme: Theme) {
        self.theme = theme
    }

}
