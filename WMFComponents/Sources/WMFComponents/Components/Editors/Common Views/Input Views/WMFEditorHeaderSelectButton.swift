import Foundation
import UIKit

final class WMFEditorHeaderSelectButton: WMFComponentView {
    
    // MARK: - Nested Types
    
    struct ViewModel {
        let title: String
        let font: UIFont
    }
    
    // MARK: - Properties
    
    let viewModel: ViewModel
    var tapAction: (() -> Void)?
    private var button: UIButton?
    
    var isSelected: Bool {
        get {
            button?.isSelected ?? false
        }
        set {
            button?.isSelected = newValue
        }
    }
    
    // MARK: - Lifecycle
    
    init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        return button?.intrinsicContentSize ?? .zero
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        return button?.sizeThatFits(size) ?? .zero
    }
    
    override func appEnvironmentDidChange() {
        
        guard let button else {
            return
        }
        
        let buttonConfig = createButtonConfig()
        button.configuration = buttonConfig
        button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
    }
    
    // MARK: - Private
    
    private func setup() {
        
        button = createButton()
        
        guard let button else {
            return
        }
        
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: button.topAnchor),
            leadingAnchor.constraint(equalTo: button.leadingAnchor),
            trailingAnchor.constraint(equalTo: button.trailingAnchor),
            bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
    }
    
    private func createButtonConfig() -> UIButton.Configuration {
        var buttonConfig = UIButton.Configuration.plain()
        
        var container = AttributeContainer()
        container.font = viewModel.font
        container.foregroundColor = theme.text
        
        buttonConfig.attributedTitle = AttributedString(viewModel.title, attributes: container)
        buttonConfig.baseForegroundColor = theme.text
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 12, bottom: 19, trailing: 12)
        buttonConfig.background.cornerRadius = 10
        
        return buttonConfig
    }
    
    private func createButtonAction() -> UIAction {
        return UIAction(title: viewModel.title, handler: { [weak self] _ in
            self?.tapAction?()
        })
    }
    
    private func buttonConfigurationUpdateHandler(button: UIButton) {
        var buttonConfig = button.configuration
        buttonConfig?.background.backgroundColor = button.isSelected ? self.theme.link : self.theme.paperBackground
        
        var container = AttributeContainer()
        container.font = viewModel.font
        container.foregroundColor = button.isSelected ? self.theme.paperBackground : self.theme.text
        
        buttonConfig?.attributedTitle = AttributedString(viewModel.title, attributes: container)

        button.configuration = buttonConfig
    }
    
    private func createButton() -> UIButton {
        
        let buttonConfig = createButtonConfig()
        let action = createButtonAction()
        let button = UIButton(configuration: buttonConfig, primaryAction: action)
        button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
        
        return button
    }
}
