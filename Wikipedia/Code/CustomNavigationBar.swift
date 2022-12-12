import UIKit

class CustomNavigationBar: SetupView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView(frame: .zero)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fill
        return stackView
    }()

    // fileprivate let bar: UINavigationBar = UINavigationBar()

    override func setup() {
        super.setup()
        
        wmf_addSubviewWithConstraintsToEdges(stackView)
    }
    
    var totalHeight: CGFloat {
        var totalHeight: CGFloat = 0
        for subview in stackView.arrangedSubviews {
            if let adjustingView = subview as? CustomNavigationBarSubviewHeightAdjusting {
                totalHeight += adjustingView.contentHeight
            }
        }
    
        return totalHeight
    }
    
    func addCollapsingSubviews(views: [CustomNavigationBarSubviewHeightAdjusting]) {
        views.forEach { stackView.addArrangedSubview($0) }
    }
}
