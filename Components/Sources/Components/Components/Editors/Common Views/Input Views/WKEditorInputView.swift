import Foundation
import UIKit

protocol WKEditorInputViewDelegate: AnyObject {
    func didTapClose()
    func didTapBold(isSelected: Bool)
    func didTapItalics(isSelected: Bool)
    func didTapTemplate(isSelected: Bool)
    func didTapReference(isSelected: Bool)
    func didTapBulletList(isSelected: Bool)
    func didTapNumberList(isSelected: Bool)
    func didTapIncreaseIndent()
    func didTapDecreaseIndent()
    func didTapHeading(type: WKEditorInputView.HeadingButtonType)
    func didTapStrikethrough(isSelected: Bool)
    func didTapSubscript(isSelected: Bool)
    func didTapSuperscript(isSelected: Bool)
    func didTapUnderline(isSelected: Bool)
    func didTapLink(isSelected: Bool)
    func didTapComment(isSelected: Bool)
}

class WKEditorInputView: WKComponentView {
    
    // MARK: - Nested Types
    
    enum HeadingButtonType {
        case paragraph
        case heading
        case subheading1
        case subheading2
        case subheading3
        case subheading4
        
        var title: String {
            switch self {
            case .paragraph: return WKSourceEditorLocalizedStrings.current.inputViewParagraph
            case .heading: return WKSourceEditorLocalizedStrings.current.inputViewHeading
            case .subheading1: return WKSourceEditorLocalizedStrings.current.inputViewSubheading1
            case .subheading2: return WKSourceEditorLocalizedStrings.current.inputViewSubheading2
            case .subheading3: return WKSourceEditorLocalizedStrings.current.inputViewSubheading3
            case .subheading4: return WKSourceEditorLocalizedStrings.current.inputViewSubheading4
            }
        }
    }
    
    // MARK: - Properties
    
    private lazy var navigationStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        label.font = WKFont.for(.headline, compatibleWith: appEnvironment.traitCollection)
        label.text = WKSourceEditorLocalizedStrings.current.inputViewTextFormatting
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(WKSFSymbolIcon.for(symbol: .multiplyCircleFill), for: .normal)
        button.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.closeButton
        button.accessibilityLabel = WKSourceEditorLocalizedStrings.current.accessibilityLabelButtonCloseMainInputView
        return button
    }()
    
    private lazy var containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var headingScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()
    
    private lazy var headingStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.alignment = .fill
        return stackView
    }()
    
    private lazy var plainToolbarView: WKEditorToolbarPlainView = {
        let view = UINib(nibName: String(describing: WKEditorToolbarPlainView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKEditorToolbarPlainView
        view.delegate = delegate
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var groupedToolbarView: WKEditorToolbarGroupedView = {
        let view = UINib(nibName: String(describing: WKEditorToolbarGroupedView.self), bundle: Bundle.module).instantiate(withOwner: nil).first as! WKEditorToolbarGroupedView
        view.delegate = delegate
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Heading Buttons
    private var paragraphButton: UIButton!
    private var headerButton: UIButton!
    private var subheader1Button: UIButton!
    private var subheader2Button: UIButton!
    private var subheader3Button: UIButton!
    private var subheader4Button: UIButton!
    
    var headingButtons: [UIButton] {
        return [paragraphButton, headerButton, subheader1Button, subheader2Button, subheader3Button, subheader4Button]
    }
    
    private var divViews: [UIView] = []
    
    private weak var delegate: WKEditorInputViewDelegate?
    
    // MARK: - Lifecycle
    
    init(delegate: WKEditorInputViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        
        addSubview(navigationStackView)
        navigationStackView.addArrangedSubview(titleLabel)
        navigationStackView.addArrangedSubview(closeButton)
        
        // pin navigation stack view to top
        NSLayoutConstraint.activate([
            navigationStackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 12),
            navigationStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 16),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: navigationStackView.trailingAnchor, constant: 16)
        ])
        
        // ---- Headings ----
        
        self.paragraphButton = headingButton(type: .paragraph)
        self.headerButton = headingButton(type: .heading)
        self.subheader1Button = headingButton(type: .subheading1)
        self.subheader2Button = headingButton(type: .subheading2)
        self.subheader3Button = headingButton(type: .subheading3)
        self.subheader4Button = headingButton(type: .subheading4)
        
        headingStackView.addArrangedSubview(paragraphButton)
        headingStackView.addArrangedSubview(headerButton)
        headingStackView.addArrangedSubview(subheader1Button)
        headingStackView.addArrangedSubview(subheader2Button)
        headingStackView.addArrangedSubview(subheader3Button)
        headingStackView.addArrangedSubview(subheader4Button)
        
        headingScrollView.addSubview(headingStackView)
        
        let headerButtonSize = headerButton.sizeThatFits(bounds.size)
        
        // pin heading stack to heading scroll view content guide
        // ensure it only scrolls horizontally
        // set heading scroll view height to largest button height
        NSLayoutConstraint.activate([
            headingScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: headingStackView.topAnchor),
            headingStackView.leadingAnchor.constraint(equalTo: headingScrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            headingScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: headingStackView.trailingAnchor, constant: 16),
            headingScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: headingStackView.bottomAnchor),
            headingScrollView.contentLayoutGuide.heightAnchor.constraint(equalTo: headingScrollView.frameLayoutGuide.heightAnchor),
            headingScrollView.heightAnchor.constraint(equalToConstant: headerButtonSize.height)
        ])
        
        // ---- Container ----
        
        containerStackView.addArrangedSubview(headingScrollView)
        let divView1 = divView()
        containerStackView.addArrangedSubview(divView1)
        containerStackView.addArrangedSubview(plainToolbarView)
        let divView2 = divView()
        containerStackView.addArrangedSubview(divView1)
        containerStackView.addArrangedSubview(groupedToolbarView)
        let divView3 = divView()
        containerStackView.addArrangedSubview(divView3)
        containerScrollView.addSubview(containerStackView)
        
        self.divViews = [divView1, divView2, divView3]
        
        // pin container stack view to container scroll view content guide
        NSLayoutConstraint.activate([
            containerScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerStackView.topAnchor),
            containerScrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor),
            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            containerScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor)
        ])
        
        addSubview(containerScrollView)
        
        // pin scroll view frame guide to outer views
        NSLayoutConstraint.activate([
            containerScrollView.frameLayoutGuide.topAnchor.constraint(equalTo: navigationStackView.bottomAnchor, constant: 18),
            containerScrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerScrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            containerScrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
        
        // Ensure it only scrolls vertically
        NSLayoutConstraint.activate([
            containerScrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: containerScrollView.frameLayoutGuide.widthAnchor)
        ])
        
        updateColors()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
        
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }

        configure(selectionState: selectionState)
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    // MARK: - Button Actions
    
    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.didTapClose()
    }
    
    // MARK: - Private Helpers
    
    private func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.accessoryBackground
        titleLabel.textColor = WKAppEnvironment.current.theme.text
        closeButton.tintColor = WKAppEnvironment.current.theme.inputAccessoryButtonTint
        divViews.forEach { view in
            view.backgroundColor = WKAppEnvironment.current.theme.border
        }
    }
    
    private func divView() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return view
    }
    
    private func headingButton(type: HeadingButtonType) -> UIButton {
        
        let font: UIFont
        switch type {
        case .paragraph: font = WKFont.for(.body, compatibleWith: traitCollection)
        case .heading: font = WKFont.for(.headline, compatibleWith: traitCollection)
        default: font = WKFont.for(.subheadline, compatibleWith: traitCollection)
        }
        
        var configuration = UIButton.Configuration.plain()
        configuration.titleTextAttributesTransformer =
           UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = font
            outgoing.foregroundColor = WKAppEnvironment.current.theme.text
            return outgoing
         }
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 19, leading: 12, bottom: 19, trailing: 12)
        let action = UIAction(title: type.title, handler: { [weak self] _ in
            
            guard let self else {
                return
            }
            
            self.headingButtons.forEach { button in
                button.isSelected = false
            }
            
            switch type {
            case .paragraph:
                paragraphButton.isSelected = true
            case .heading:
                headerButton.isSelected = true
            case .subheading1:
                subheader1Button.isSelected = true
            case .subheading2:
                subheader2Button.isSelected = true
            case .subheading3:
                subheader3Button.isSelected = true
            case .subheading4:
                subheader4Button.isSelected = true
            }
            
            delegate?.didTapHeading(type: type)
        })
        
        return UIButton(configuration: configuration, primaryAction: action)
    }
    
    func configure(selectionState: WKSourceEditorSelectionState) {
        headingButtons.forEach { $0.isSelected = false }

        if selectionState.isHeading {
            headerButton.isSelected = true
        } else if selectionState.isSubheading1 {
            subheader1Button.isSelected = true
        } else if selectionState.isSubheading2 {
            subheader2Button.isSelected = true
        } else if selectionState.isSubheading3 {
            subheader3Button.isSelected = true
        } else if selectionState.isSubheading4 {
            subheader4Button.isSelected = true
        } else {
            paragraphButton.isSelected = true
        }
    }
}
