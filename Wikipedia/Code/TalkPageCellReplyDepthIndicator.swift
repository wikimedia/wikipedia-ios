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
        setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultHigh, for: .vertical)
        setContentHuggingPriority(.defaultLow, for: .horizontal)

        addSubview(stickContainer)

        NSLayoutConstraint.activate([
            stickContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickContainer.topAnchor.constraint(equalTo: topAnchor),
            stickContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        super.sizeThatFits(size)
        
        let availableHeight = size.height
        let availableWidth = size.width
        
        let drawableSticks = min(depth, Int(availableWidth / (stickWidth + stickHorizontalSpacing)))
        var drawnCount = 0
        
        guard drawableSticks >= 1 else {
            return CGSize.zero
        }

        var lineFrames: [CGRect] = []
        for lineDepth in 1...drawableSticks {
            var height = availableHeight - stickHeightDelta * CGFloat(lineDepth)
            if height <= 0 {
                height = 3
            }
            lineFrames.append(CGRect(x: availableWidth - CGFloat(lineDepth) * (stickHorizontalSpacing + stickWidth), y: 0, width: stickWidth, height: height))
            
            drawnCount += 1
        }
        
        var maxX = CGFloat(0)
        var maxY = CGFloat(0)
        for frame in lineFrames {
            if frame.maxX > maxX {
                maxX = frame.maxX
            }
            if frame.maxY > maxY {
                maxY = frame.maxY
            }
        }
        
        return CGSize(width: maxX + stickHorizontalSpacing, height: maxY)
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
            var height = availableHeight - stickHeightDelta * CGFloat(lineDepth)
            if height <= 0 {
                height = 3
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
            // depthLabel.text = "+\(depth-drawnCount + intersectingViews)"
            // depthLabel.sizeToFit()
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
