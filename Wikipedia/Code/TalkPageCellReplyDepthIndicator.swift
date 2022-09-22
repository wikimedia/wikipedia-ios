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
        setContentCompressionResistancePriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .vertical)
        setContentHuggingPriority(.required, for: .horizontal)

        addSubview(stickContainer)

        NSLayoutConstraint.activate([
            stickContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickContainer.topAnchor.constraint(equalTo: topAnchor),
            stickContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func expectedWidth() -> CGFloat {
        return (CGFloat(depth) * (stickWidth + stickHorizontalSpacing))
    }
    
    func expectedHeight() -> CGFloat {
        return CGFloat(depth) * CGFloat(stickHeightDelta)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

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
                drawnCount += 1
                continue
            }
            let line = UIView(frame: CGRect(x: availableWidth - CGFloat(lineDepth) * (stickHorizontalSpacing + stickWidth), y: 0, width: stickWidth, height: height))
            line.backgroundColor = theme.colors.depthMarker
            stickContainer.addSubview(line)
            drawnCount += 1
        }

        if drawnCount < depth {
            addSubview(depthLabel)
            depthLabel.frame.origin = stickContainer.frame.origin
            depthLabel.text = "+\(depth-drawnCount) "
            depthLabel.sizeToFit()
            depthLabel.textColor = theme.colors.depthMarker

            var intersectingViews = 0

            for line in stickContainer.subviews {
                if line.frame.intersects(depthLabel.frame) {
                    intersectingViews += 1
                    line.alpha = 0
                }
            }
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
