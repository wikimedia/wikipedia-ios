
import Foundation
import UIKit

class WKEditorDestructiveView: WKComponentView {

    // MARK: Properties
    
    private lazy var label: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.body, compatibleWith: appEnvironment.traitCollection)
        return label
    }()
    
    // MARK: Lifecycle
    
    required init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 22, bottom: 8, trailing: 22)
        
        addSubview(label)
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: label.topAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor)
        ])
        
        updateColors()
    }
    
    // MARK: Internal
    
    func configure(viewModel: WKEditorDestructiveViewModel) {
        label.text = viewModel.text
    }
    
    // MARK: Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: Private Helpers
    
    private func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        label.textColor = WKAppEnvironment.current.theme.destructive
    }
}
