import Foundation
import UIKit

class WKEditorHeaderSelectView: WKComponentView {
    
    // MARK: Properties
    
    private lazy var label: UILabel = {
       let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.body, compatibleWith: appEnvironment.traitCollection)
        return label
    }()
    
    private lazy var imageView: UIImageView = {
        let image = WKIcon.checkmark
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
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
        addSubview(imageView)
        NSLayoutConstraint.activate([
            layoutMarginsGuide.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            layoutMarginsGuide.topAnchor.constraint(equalTo: label.topAnchor),
            layoutMarginsGuide.bottomAnchor.constraint(equalTo: label.bottomAnchor),
            label.trailingAnchor.constraint(equalTo: imageView.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
        ])
        
        updateColors()
    }
    
    // MARK: Internal
    
    func configure(viewModel: WKEditorHeaderSelectViewModel) {
        imageView.isHidden = !viewModel.isSelected
        switch viewModel.configuration {
        case .paragraph:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewParagraph
        case .heading:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewHeading
        case .subheading1:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading1
        case .subheading2:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading2
        case .subheading3:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading3
        case .subheading4:
            label.text = WKSourceEditorLocalizedStrings.current.inputViewSubheading4
        }
    }
    
    // MARK: Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: Private Helpers
    
    func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        label.textColor = WKAppEnvironment.current.theme.text
        imageView.tintColor = WKAppEnvironment.current.theme.link
    }
}
