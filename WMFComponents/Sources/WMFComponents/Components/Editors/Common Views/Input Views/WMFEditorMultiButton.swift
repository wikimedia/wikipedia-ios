import Foundation
import UIKit

protocol WMFEditorMultiSelectButtonDelegate: AnyObject {
    func didSelectIndex(_ index: Int, isSelected: Bool, multiSelectButton: WMFEditorMultiButton)
}

final class WMFEditorMultiButton: WMFComponentView {
    
    // MARK: - Nested Types
    
    struct ViewModel {
        let icon: UIImage?
        let accessibilityLabel: String
    }
    
    // MARK: - Properties
    
    private let viewModels: [ViewModel]
    private var buttons: [UIButton] = []
    private weak var delegate: WMFEditorMultiSelectButtonDelegate?
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        stackView.spacing = 2
        return stackView
    }()
    
    // MARK: - Lifecycle
    
    init(viewModels: [ViewModel], delegate: WMFEditorMultiSelectButtonDelegate) {
        self.viewModels = viewModels
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        createAndAddButtonsToStackView()
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            topAnchor.constraint(equalTo: stackView.topAnchor),
            leadingAnchor.constraint(equalTo: stackView.leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: stackView.bottomAnchor)
        ])
        
        layer.cornerRadius = 10
        layer.masksToBounds = true
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        
        for (viewModel, button) in zip(viewModels, buttons) {
            let buttonConfig = createButtonConfig(image: viewModel.icon)
            button.configuration = buttonConfig
            button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
        }
    }
    
    // MARK: - Internal
    
    func toggleSelectionIndex(_ index: Int, shouldSelect: Bool) {
        guard buttons.count > index else {
            return
        }
        
        buttons[index].isSelected = shouldSelect
    }
    
    func toggleEnableIndex(_ index: Int, shouldEnable: Bool) {
        guard buttons.count > index else {
            return
        }
        
        buttons[index].isEnabled = shouldEnable
    }
    
    // MARK: - Private
    
    private func createAndAddButtonsToStackView() {
        var buttons: [UIButton] = []
        for (index, viewModel) in viewModels.enumerated() {
            let button = createButton(viewModel: viewModel, tapAction: { [weak self] in
                guard let self else {
                    return
                }
                let isSelected = buttons[index].isSelected
                delegate?.didSelectIndex(index, isSelected: isSelected, multiSelectButton: self)
            })
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }
        self.buttons = buttons
    }
    
    private func createButtonConfig(image: UIImage?) -> UIButton.Configuration {
        var buttonConfig = UIButton.Configuration.plain()
        
        buttonConfig.baseForegroundColor = theme.text
        buttonConfig.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 19, bottom: 19, trailing: 19)
        buttonConfig.background.cornerRadius = 0
        buttonConfig.image = image
        
        return buttonConfig
    }
    
    private func createButtonAction(action: @escaping () -> Void) -> UIAction {
        return UIAction(title: "", handler: { _ in
            action()
        })
    }
    
    private func buttonConfigurationUpdateHandler(button: UIButton) {
        var buttonConfig = button.configuration
        
        buttonConfig?.background.backgroundColor = button.isSelected ? self.theme.editorButtonSelectedBackground : self.theme.midBackground
        
        button.configuration = buttonConfig
    }
    
    private func createButton(viewModel: ViewModel, tapAction: @escaping () -> Void) -> UIButton {
        
        let buttonConfig = createButtonConfig(image: viewModel.icon)
        let action = createButtonAction(action: tapAction)
        let button = UIButton(configuration: buttonConfig, primaryAction: action)
        button.configurationUpdateHandler = buttonConfigurationUpdateHandler(button:)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityLabel = viewModel.accessibilityLabel
        
        return button
    }
}
