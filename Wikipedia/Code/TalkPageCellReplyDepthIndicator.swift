import UIKit
import WMF

final class TalkPageCellReplyDepthIndicator: SetupView {

    // MARK: - Properties

    var depth: Int

    private let lineWidth: CGFloat = 1
    private let lineHorizontalSpacing: CGFloat = 6
    private let lineHeightDelta: CGFloat = 8
    private let maxAllowedLines = 10

    fileprivate var theme: Theme = .light

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.distribution = .fillEqually
        stackView.spacing = lineHorizontalSpacing
        return stackView
    }()

    lazy var depthLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var depthLabelContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        addSubview(stackView)
        addSubview(depthLabelContainer)
        depthLabelContainer.addSubview(depthLabel)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            depthLabel.leadingAnchor.constraint(equalTo: depthLabelContainer.leadingAnchor),
            depthLabel.trailingAnchor.constraint(equalTo: depthLabelContainer.trailingAnchor),
            depthLabel.topAnchor.constraint(equalTo: depthLabelContainer.topAnchor),
            depthLabel.bottomAnchor.constraint(lessThanOrEqualTo: depthLabelContainer.bottomAnchor),
            
            depthLabelContainer.topAnchor.constraint(equalTo: stackView.topAnchor),
            depthLabelContainer.leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            depthLabelContainer.bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
    }
    
    // MARK: - Configure

    func configure(viewModel: TalkPageCellCommentViewModel) {
        depth = viewModel.replyDepth
        
        let numberOfLinesToDraw = min(depth, maxAllowedLines)
        for index in (1...numberOfLinesToDraw) {
            let line = UIView(frame: .zero)
            line.translatesAutoresizingMaskIntoConstraints = false
            stackView.addArrangedSubview(line)
            
            NSLayoutConstraint.activate([
                line.widthAnchor.constraint(equalToConstant: lineWidth),
                line.heightAnchor.constraint(equalTo: stackView.heightAnchor, multiplier: CGFloat(index)/CGFloat(numberOfLinesToDraw))
            ])
        }
        
        let numberRemaining = depth - numberOfLinesToDraw
        depthLabel.text = "+\(numberRemaining) "
        depthLabelContainer.isHidden = numberRemaining == 0
    }
}

extension TalkPageCellReplyDepthIndicator: Themeable {

    func apply(theme: Theme) {
        self.theme = theme
        for line in stackView.arrangedSubviews {
            line.backgroundColor = theme.colors.depthMarker
        }
        depthLabel.textColor = theme.colors.depthMarker
        depthLabelContainer.backgroundColor = theme.colors.paperBackground
    }

}
