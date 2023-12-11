import Foundation
import UIKit

class WKEditorSelectionDetailView: WKComponentView {
    
    // MARK: - Properties
    
    private lazy var typeLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.body, compatibleWith: appEnvironment.traitCollection)
        label.text = WKSourceEditorLocalizedStrings.current.inputViewStyle
        return label
    }()
    
    private lazy var selectionLabel: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.body, compatibleWith: appEnvironment.traitCollection)
        label.textAlignment = .right
        return label
    }()
    
    private lazy var disclosureImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = WKIcon.chevronRight
        return imageView
    }()
    
    private(set) var lastSelectionState: WKSourceEditorSelectionState?

    // MARK: - Lifecycle
    
    required init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 22, bottom: 8, trailing: 22)
        
        addSubview(typeLabel)
        addSubview(selectionLabel)
        addSubview(disclosureImageView)
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: typeLabel.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: disclosureImageView.trailingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: typeLabel.topAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: typeLabel.bottomAnchor),
            typeLabel.trailingAnchor.constraint(equalTo: selectionLabel.leadingAnchor),
            selectionLabel.trailingAnchor.constraint(equalTo: disclosureImageView.leadingAnchor, constant: -8),
            selectionLabel.centerYAnchor.constraint(equalTo: disclosureImageView.centerYAnchor),
            selectionLabel.centerYAnchor.constraint(equalTo: typeLabel.centerYAnchor)
        ])
        
        updateColors()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
    
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }
        
        self.lastSelectionState = selectionState
        
        configure(selectionState: selectionState)
    }
    
    // MARK: - Internal
    
    func configure(selectionState: WKSourceEditorSelectionState) {
        if selectionState.isHeading {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewHeading
        } else if selectionState.isSubheading1 {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading1
        } else if selectionState.isSubheading2 {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading2
        } else if selectionState.isSubheading3 {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading3
        } else if selectionState.isSubheading4 {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading4
        } else {
            selectionLabel.text = WKSourceEditorLocalizedStrings.current.inputViewParagraph
        }
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Private Helpers
    
    private func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        disclosureImageView.tintColor = WKAppEnvironment.current.theme.inputAccessoryButtonTint
        typeLabel.textColor = WKAppEnvironment.current.theme.text
        selectionLabel.textColor = WKAppEnvironment.current.theme.text
    }
}
