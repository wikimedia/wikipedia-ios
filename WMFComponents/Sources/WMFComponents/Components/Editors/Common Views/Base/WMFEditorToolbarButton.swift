import Foundation
import UIKit

class WMFEditorToolbarButton: WMFComponentView {
    
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
        
        layer.cornerRadius = 4
        clipsToBounds = true

        isAccessibilityElement = true
        accessibilityTraits = isSelected ? [.button, .selected] : [.button]
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
        button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
    }
    
    // MARK: - Button passthrough methods
    
    var isSelected: Bool {
        get {
            return button?.isSelected ?? false
        }
        set {
            button?.isSelected = newValue
            accessibilityTraits = button?.accessibilityTraits ?? []
        }
    }
    
    var isEnabled: Bool {
        get {
            return button?.isEnabled ?? true
        }
        set {
            button?.isEnabled = newValue
            accessibilityTraits = button?.accessibilityTraits ?? []
        }
    }
    
    func setImage(_ image: UIImage?) {
        
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
        
        buttonConfig.baseForegroundColor = theme.text
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        buttonConfig.background.cornerRadius = 0
        if let image {
            buttonConfig.image = image
        }
        
        return buttonConfig
    }
    
    private func buttonConfigurationUpdateHandler(button: UIButton) {
        var buttonConfig = button.configuration
        buttonConfig?.background.backgroundColor = button.isSelected ? self.theme.editorButtonSelectedBackground : theme.paperBackground
        button.configuration = buttonConfig
    }
    
    private func createButton() -> UIButton {
        
        let buttonConfig = createButtonConfig()
        let button = UIButton(configuration: buttonConfig)
        button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
        
        return button
    }
}
