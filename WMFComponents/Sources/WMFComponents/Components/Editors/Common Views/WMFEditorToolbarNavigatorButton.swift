import Foundation
import UIKit

class WMFEditorToolbarNavigatorButton: WMFComponentView {
    
    // MARK: - Properties
    
    private var button: UIButton?
    private var image: UIImage?
    
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
        button = createButton()
        
        guard let button else {
            return
        }
        
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        button.isAccessibilityElement = false

        translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.topAnchor.constraint(equalTo: topAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        // Increase touch targets & make widths more consistent
        let superSize = super.intrinsicContentSize
        return CGSize(width: max(superSize.width, 36), height: max(superSize.height, 36))
    }
    
    override func appEnvironmentDidChange() {
        
        guard let button else {
            return
        }
        
        let buttonConfig = createButtonConfig(image: image)
        button.configuration = buttonConfig
    }
    
    // MARK: - Button passthrough methods
    
    func setImage(_ image: UIImage?, for state: UIControl.State) {
        
        guard let button else {
            return
        }
        
        self.image = image
        
        var buttonConfig = button.configuration
        buttonConfig?.image = image
        button.configuration = buttonConfig
    }
    
    func addTarget(_ target: Any?, action: Selector, for controlEvent: UIControl.Event) {
        button?.addTarget(target, action: action, for: controlEvent)
    }

    func removeTarget(_ target: Any?, action: Selector?, for controlEvent: UIControl.Event) {
        button?.removeTarget(target, action: action, for: controlEvent)
    }
    
    // MARK: - Private Helpers
    
    private func createButtonConfig(image: UIImage? = nil) -> UIButton.Configuration {
        var buttonConfig = UIButton.Configuration.plain()
        
        buttonConfig.baseForegroundColor = theme.link
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        buttonConfig.background.cornerRadius = 0
        if let image {
            buttonConfig.image = image
        }
        
        return buttonConfig
    }
    
    private func createButton() -> UIButton {
        
        let buttonConfig = createButtonConfig()
        let button = UIButton(configuration: buttonConfig)
        
        return button
    }
}
