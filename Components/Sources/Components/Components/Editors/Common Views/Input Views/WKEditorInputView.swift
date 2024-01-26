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
        
        func font(traitCollection: UITraitCollection) -> UIFont {
            switch self {
            case .paragraph: return WKFont.for(.body, compatibleWith: traitCollection)
            default:
                return WKFont.for(.headline, compatibleWith: traitCollection)
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
        label.font = WKFont.for(.boldTitle3, compatibleWith: appEnvironment.traitCollection)
        label.text = WKSourceEditorLocalizedStrings.current.inputViewTextFormatting
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        setCloseButtonImage(button: button)
        button.addTarget(self, action: #selector(close(_:)), for: .touchUpInside)
        button.accessibilityIdentifier = WKSourceEditorAccessibilityIdentifiers.current?.closeButton
        button.accessibilityLabel = WKSourceEditorLocalizedStrings.current.accessibilityLabelButtonCloseMainInputView
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()
    
    private lazy var containerScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.bounces = false
        scrollView.clipsToBounds = true
        scrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
        return scrollView
    }()
    
    private lazy var containerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.alignment = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private lazy var headingButtonTypes: [HeadingButtonType] = {
        return [.paragraph, .heading, .subheading1, .subheading2, .subheading3, .subheading4]
    }()
    
    private lazy var headerSelectScrollView: WKEditorHeaderSelectScrollView = {
        let configurations: [WKEditorHeaderSelectButton.Configuration] = headingButtonTypes.map {
            
            let title = $0.title
            let font = $0.font(traitCollection: traitCollection)
            let item = WKEditorHeaderSelectButton.Configuration(title: title, font: font)
            
            return item
        }

        let scrollingChoiceView = WKEditorHeaderSelectScrollView(configurations: configurations, delegate: self)
        scrollingChoiceView.translatesAutoresizingMaskIntoConstraints = false
        return scrollingChoiceView
    }()
    
    private lazy var multiSelectStackView1: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var multiSelectStackView2: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var accessibilityMultiSelectStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 8
        stackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()
    
    private lazy var multiButtonBoldItalic: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .bold),
            WKSFSymbolIcon.for(symbol: .italic)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonUnderlineStrikethrough: WKEditorMultiButton = {
        
        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .underline),
            WKSFSymbolIcon.for(symbol: .strikethrough)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonReferenceLink: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .quoteOpening),
            WKSFSymbolIcon.for(symbol: .link)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonBulletNumberList: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .listBullet),
            WKSFSymbolIcon.for(symbol: .listNumber)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonIndentIncreaseDecrease: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .decreaseIndent),
            WKSFSymbolIcon.for(symbol: .increaseIndent)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonSubscriptSuperscript: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .textFormatSuperscript),
            WKSFSymbolIcon.for(symbol: .textFormatSubscript)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private lazy var multiButtonTemplateComment: WKEditorMultiButton = {

        let configuration = WKEditorMultiButton.Configuration(icons: [
            WKSFSymbolIcon.for(symbol: .curlybraces),
            WKSFSymbolIcon.for(symbol: .exclamationMarkCircle)
        ])

        let button = WKEditorMultiButton(configuration: configuration, delegate: self)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
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
        
        // ---- Container ----
        
        containerStackView.addArrangedSubview(headerSelectScrollView)
        
        if traitCollection.preferredContentSizeCategory.isAccessibilityCategory {
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonBoldItalic)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonUnderlineStrikethrough)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonReferenceLink)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonBulletNumberList)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonIndentIncreaseDecrease)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonSubscriptSuperscript)
            accessibilityMultiSelectStackView.addArrangedSubview(multiButtonTemplateComment)
            accessibilityMultiSelectStackView.addArrangedSubview(multiSelectStackView1)
            accessibilityMultiSelectStackView.addArrangedSubview(multiSelectStackView1)
            containerStackView.addArrangedSubview(accessibilityMultiSelectStackView)
        } else {
            multiSelectStackView1.addArrangedSubview(multiButtonBoldItalic)
            multiSelectStackView1.addArrangedSubview(multiButtonUnderlineStrikethrough)
            multiSelectStackView1.addArrangedSubview(multiButtonReferenceLink)
            containerStackView.addArrangedSubview(multiSelectStackView1)
            
            multiSelectStackView2.addArrangedSubview(multiButtonBulletNumberList)
            multiSelectStackView2.addArrangedSubview(multiButtonIndentIncreaseDecrease)
            multiSelectStackView2.addArrangedSubview(multiButtonSubscriptSuperscript)
            multiSelectStackView2.addArrangedSubview(multiButtonTemplateComment)
            containerStackView.addArrangedSubview(multiSelectStackView2)
        }

        addSubview(containerScrollView)
        containerScrollView.addSubview(containerStackView)

        // pin container stack view to container scroll view content guide
        NSLayoutConstraint.activate([
            containerScrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerStackView.topAnchor),
            containerScrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor),
            containerScrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor),
            containerScrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerStackView.bottomAnchor)
        ])
        
        // pin scroll view to outer views
        NSLayoutConstraint.activate([
            containerScrollView.topAnchor.constraint(equalTo: navigationStackView.bottomAnchor, constant: 18),
            containerScrollView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            containerScrollView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor),
            containerScrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
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

        // Headers
        if selectionState.isHeading {
            headerSelectScrollView.selectIndex(1)
        } else if selectionState.isSubheading1 {
            headerSelectScrollView.selectIndex(2)
        } else if selectionState.isSubheading2 {
            headerSelectScrollView.selectIndex(3)
        } else if selectionState.isSubheading3 {
            headerSelectScrollView.selectIndex(4)
        } else if selectionState.isSubheading4 {
            headerSelectScrollView.selectIndex(5)
        } else {
            headerSelectScrollView.selectIndex(0) // Paragraph
        }
        
        // Top row
        multiButtonBoldItalic.toggleSelectionIndex(0, shouldSelect: selectionState.isBold)
        multiButtonBoldItalic.toggleSelectionIndex(1, shouldSelect: selectionState.isItalics)
        
        multiButtonUnderlineStrikethrough.toggleSelectionIndex(0, shouldSelect: selectionState.isUnderline)
        multiButtonUnderlineStrikethrough.toggleSelectionIndex(1, shouldSelect: selectionState.isStrikethrough)
        
        multiButtonReferenceLink.toggleSelectionIndex(0, shouldSelect: selectionState.isHorizontalReference)
        multiButtonReferenceLink.toggleSelectionIndex(1, shouldSelect: selectionState.isSimpleLink)
        
        // Bottom row
        multiButtonBulletNumberList.toggleSelectionIndex(0, shouldSelect: selectionState.isBulletSingleList || selectionState.isBulletMultipleList)
        multiButtonBulletNumberList.toggleEnableIndex(0, shouldEnable: !selectionState.isNumberSingleList && !selectionState.isNumberMultipleList)
        
        multiButtonBulletNumberList.toggleSelectionIndex(1, shouldSelect: selectionState.isNumberSingleList || selectionState.isNumberMultipleList)
        multiButtonBulletNumberList.toggleEnableIndex(1, shouldEnable: !selectionState.isBulletSingleList && !selectionState.isBulletMultipleList)
        
        multiButtonIndentIncreaseDecrease.toggleEnableIndex(0, shouldEnable: selectionState.isBulletMultipleList || selectionState.isNumberMultipleList)
        multiButtonIndentIncreaseDecrease.toggleEnableIndex(1, shouldEnable: selectionState.isBulletSingleList || selectionState.isBulletMultipleList || selectionState.isNumberSingleList || selectionState.isNumberMultipleList)
        
        multiButtonSubscriptSuperscript.toggleSelectionIndex(0, shouldSelect: selectionState.isSuperscript)
        multiButtonSubscriptSuperscript.toggleSelectionIndex(1, shouldSelect: selectionState.isSubscript)
        
        multiButtonTemplateComment.toggleSelectionIndex(0, shouldSelect: selectionState.isHorizontalTemplate)
        multiButtonTemplateComment.toggleSelectionIndex(1, shouldSelect: selectionState.isComment)
    }
    
    // MARK: - Overrides
    
    override func appEnvironmentDidChange() {
        updateColors()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        containerScrollView.flashScrollIndicators()
    }
    
    // MARK: - Button Actions
    
    @objc private func close(_ sender: UIBarButtonItem) {
        delegate?.didTapClose()
    }
    
    // MARK: - Private Helpers
    
    private func updateColors() {
        backgroundColor = WKAppEnvironment.current.theme.paperBackground
        titleLabel.textColor = WKAppEnvironment.current.theme.text
        setCloseButtonImage(button: closeButton)
    }
    
    private func setCloseButtonImage(button: UIButton) {
        let image = WKSFSymbolIcon.for(symbol: .multiplyCircleFill, font: .title1, paletteColors: [theme.secondaryText, theme.midBackground])
        button.setImage(image, for: .normal)
    }
}

// MARK: - WKEditorHeaderSelectScrollViewDelegate

extension WKEditorInputView: WKEditorHeaderSelectScrollViewDelegate {
    func didSelectIndex(_ index: Int, headerSelectScrollView: WKEditorHeaderSelectScrollView) {
        guard headingButtonTypes.count > index else {
            return
        }
        
        let headingType = headingButtonTypes[index]
        delegate?.didTapHeading(type: headingType)
    }
}

// MARK: - WKEditorHeaderSelectScrollViewDelegate

extension WKEditorInputView: WKEditorMultiSelectButtonDelegate {
    func didSelectIndex(_ index: Int, isSelected: Bool, multiSelectButton: WKEditorMultiButton) {
        
        switch multiSelectButton {
        case multiButtonBoldItalic:
            switch index {
            case 0:
                delegate?.didTapBold(isSelected: isSelected)
            case 1:
                delegate?.didTapItalics(isSelected: isSelected)
            default:
                break
            }
        case multiButtonUnderlineStrikethrough:
            switch index {
            case 0:
                delegate?.didTapUnderline(isSelected: isSelected)
            case 1:
                delegate?.didTapStrikethrough(isSelected: isSelected)
            default:
                break
            }
        case multiButtonReferenceLink:
            switch index {
            case 0:
                delegate?.didTapReference(isSelected: isSelected)
            case 1:
                delegate?.didTapLink(isSelected: isSelected)
            default:
                break
            }
        case multiButtonBulletNumberList:
            switch index {
            case 0:
                delegate?.didTapBulletList(isSelected: isSelected)
            case 1:
                delegate?.didTapNumberList(isSelected: isSelected)
            default:
                break
            }
        case multiButtonIndentIncreaseDecrease:
            switch index {
            case 0:
                delegate?.didTapDecreaseIndent()
            case 1:
                delegate?.didTapIncreaseIndent()
            default:
                break
            }
        case multiButtonSubscriptSuperscript:
            switch index {
            case 0:
                delegate?.didTapSuperscript(isSelected: isSelected)
            case 1:
                delegate?.didTapSubscript(isSelected: isSelected)
            default:
                break
            }
        case multiButtonTemplateComment:
            switch index {
            case 0:
                delegate?.didTapTemplate(isSelected: isSelected)
            case 1:
                delegate?.didTapComment(isSelected: isSelected)
            default:
                break
            }
        default:
            break
        }
    }
}
