import UIKit
import WMF

// TODO
final class TalkPageCellCommentDepthIndicator: SetupView {

    let depth: Int
    let label = UILabel()

    required init(depth: Int) {
        self.depth = depth
        super.init(frame: .zero)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError()
    }

    override func setup() {
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.font = UIFont.wmf_font(.body)
        label.adjustsFontForContentSizeCategory = true
        label.text = " \(depth) "
        addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

}

extension TalkPageCellCommentDepthIndicator: Themeable {

    func apply(theme: Theme) {
        label.textColor = theme.colors.paperBackground
        label.backgroundColor = theme.colors.link
    }

}
