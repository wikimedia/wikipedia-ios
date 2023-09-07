import Foundation
import UIKit

class WKEditorToolbarButton: WKComponentView {
    
    // MARK: - Properties
    
    private lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        layer.cornerRadius = 4
        clipsToBounds = true
        
        translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        
        updateColors()
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        // Increase touch targets & make widths more consistent
        let superSize = super.intrinsicContentSize
        return CGSize(width: max(superSize.width, 36), height: max(superSize.height, 36))
    }
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Button passthrough methods
    
    var isSelected: Bool {
        get {
            return button.isSelected
        }
        set {
            button.isSelected = newValue
            updateColors()
        }
    }
    
    func setImage(_ image: UIImage?, for state: UIControl.State) {
        button.setImage(image, for: state)
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvent: UIControl.Event) {
        button.addTarget(target, action: action, for: controlEvent)
    }

    func removeTarget(_ target: Any?, action: Selector?, for controlEvent: UIControl.Event) {
        button.removeTarget(target, action: action, for: controlEvent)
    }
    
    // MARK: - Private Helpers
    
    func updateColors() {
        button.tintColor = isSelected ? WKAppEnvironment.current.theme.inputAccessoryButtonSelectedTint : WKAppEnvironment.current.theme.inputAccessoryButtonTint
        backgroundColor = self.isSelected ? WKAppEnvironment.current.theme.inputAccessoryButtonSelectedBackgroundColor : .clear
    }
}
