import UIKit

@objc(WMFThemeableTextField)
public class ThemeableTextField: UITextField, Themeable {
    var theme = Theme.standard
    var hasBorder = false
    
    func setup() {
        let image = #imageLiteral(resourceName: "clear-mini")
        let clearButton = UIButton(frame: CGRect(origin: .zero, size: image.size))
        clearButton.setImage(image, for: .normal)
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
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
    override public var placeholder: String? {
        didSet {
            _placeholder = placeholder
            guard let newPlaceholder = placeholder else {
                return
            }
            attributedPlaceholder = NSAttributedString(string: newPlaceholder, attributes: [NSForegroundColorAttributeName: theme.colors.tertiaryText])
        }
    }
    
    fileprivate func _clear() {
        text = nil
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
        apply(theme: theme, withBorder: false)
    }
 
    func apply(theme: Theme, withBorder: Bool) {
        self.theme = theme
        rightView?.tintColor = theme.colors.tertiaryText
        backgroundColor = theme.colors.paperBackground
        textColor = theme.colors.primaryText
        placeholder = _placeholder
        keyboardAppearance = theme.keyboardAppearance
        borderStyle = .none
        layer.backgroundColor = backgroundColor?.cgColor
        layer.masksToBounds = false
        layer.shadowColor = textColor?.cgColor
        layer.shadowOffset = CGSize(width: 0.0, height: 1.0)
        layer.shadowOpacity = 1.0
        layer.shadowRadius = 0.0
    }
}
