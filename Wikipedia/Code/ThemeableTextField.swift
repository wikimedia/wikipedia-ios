import UIKit

@objc(WMFThemeableTextField)
class ThemeableTextField: UITextField, Themeable {
    var theme = Theme.standard
    
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
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    fileprivate var _placeholder: String?
    override var placeholder: String? {
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
    func apply(theme: Theme) {
        self.theme = theme
        rightView?.tintColor = theme.colors.tertiaryText
        backgroundColor = theme.colors.chromeBackground
        textColor = theme.colors.chromeText
        placeholder = _placeholder
    }
    
}
