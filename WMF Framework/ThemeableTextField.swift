import UIKit

@objc(WMFThemeableTextField)
open class ThemeableTextField: UITextField, Themeable {
    var theme = Theme.light
    @objc public var isUnderlined = true
    private var clearButton: UIButton?
    public var clearAccessibilityLabel: String? {
        get {
            return clearButton?.accessibilityLabel
        } set {
            clearButton?.accessibilityLabel = newValue
        }
    }
    
    func setup() {
        let image = #imageLiteral(resourceName: "clear-mini")
        clearButton = UIButton(frame: CGRect(origin: .zero, size: image.size))
        clearButton?.setImage(image, for: .normal)
        clearButton?.addTarget(self, action: #selector(clear), for: .touchUpInside)
        rightView = clearButton
        rightViewMode = .whileEditing
        textAlignment = .natural
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate var _placeholder: String?
    override open var placeholder: String? {
        didSet {
            _placeholder = placeholder
            guard let newPlaceholder = placeholder else {
                return
            }
            attributedPlaceholder = NSAttributedString(string: newPlaceholder, attributes: [NSAttributedString.Key.foregroundColor: theme.colors.secondaryText])
        }
    }
    
    fileprivate func _clear() {
        text = nil
        sendActions(for: .editingChanged)
    }
    
    @objc(clear)
    fileprivate func clear() {
        guard let shouldClear = delegate?.textFieldShouldClear?(self) else {
            _clear()
            return
        }
        
        guard shouldClear else {
            return
        }
       
        _clear()
    }
    
    @objc(applyTheme:)
    public func apply(theme: Theme) {
        self.theme = theme
        rightView?.tintColor = theme.colors.tertiaryText
        backgroundColor = theme.colors.paperBackground
        textColor = theme.colors.primaryText
        placeholder = _placeholder
        keyboardAppearance = theme.keyboardAppearance
        borderStyle = .none
        if isUnderlined {
            layer.masksToBounds = false
            layer.shadowColor = theme.colors.tertiaryText.cgColor
            layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
            layer.shadowOpacity = 1.0
            layer.shadowRadius = 0.0
        } else {
            layer.masksToBounds = true
            layer.shadowColor = nil
            layer.shadowOffset = CGSize.zero
            layer.shadowOpacity = 0.0
            layer.shadowRadius = 0.0
        }

    }
}


