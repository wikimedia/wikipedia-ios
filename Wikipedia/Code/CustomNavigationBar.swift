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
    
    func addCollapsingSubviews(views: [CustomNavigationBarSubview]) {
        views.forEach { stackView.addArrangedSubview($0) }
    }
}
