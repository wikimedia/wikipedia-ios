import UIKit
import WMF

final class TalkPageCellCommentSeparator: SetupView {

    // MARK: - UI Elements

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    lazy var horizontalLine: VerticalSpacerView = {
        let view = VerticalSpacerView.spacerWith(space: 1)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override var intrinsicContentSize: CGSize {
        return UIView.layoutFittingExpandedSize
    }
    
    override var semanticContentAttribute: UISemanticContentAttribute {
        didSet {
            updateSemanticContentAttribute(semanticContentAttribute)
        }
    }

    // MARK: - Lifecycle

    override func setup() {
        addSubview(stackView)
        stackView.addArrangedSubview(horizontalLine)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20)
        ])
    }
    
    private func updateSemanticContentAttribute(_ semanticContentAttribute: UISemanticContentAttribute) {
        stackView.semanticContentAttribute = semanticContentAttribute
        horizontalLine.semanticContentAttribute = semanticContentAttribute
    }

}

extension TalkPageCellCommentSeparator: Themeable {

    func apply(theme: Theme) {
        horizontalLine.backgroundColor = theme.colors.tertiaryText
    }

}
