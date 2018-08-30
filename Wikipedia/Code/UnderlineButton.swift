import UIKit

@IBDesignable
@objc(WMFUnderlineButton)
class UnderlineButton: AutoLayoutSafeMultiLineButton {
    var underline: UIView?
    @IBInspectable var underlineHeight: CGFloat = 1.0 {
        didSet {
            underline?.frame = underlineRect
        }
    }
    @IBInspectable var useDefaultFont: Bool = true

    override func setup() {
        super.setup()
        titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 5, right: 0)
        configureStyle()
    }

    private func configureStyle() {
        if useDefaultFont {
            titleLabel?.font = UIFont.wmf_font(.subheadline)
        }
        addUnderline()
        setTitleColor(tintColor, for: .selected)
    }

    private func addUnderline() {
        let view = UIView()
        view.backgroundColor = tintColor
        view.frame = underlineRect
        view.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        self.addSubview(view)
        underline = view
        updateUnderlineAlpha()
    }

    private var underlineRect: CGRect {
        return CGRect(x: 0, y: bounds.size.height - underlineHeight, width: bounds.size.width, height: underlineHeight)
    }

    override var isSelected: Bool {
        didSet {
            updateUnderlineAlpha()
        }
    }

    private func updateUnderlineAlpha() {
        if isSelected {
            underline?.alpha = 1
        } else {
            underline?.alpha = 0
        }
    }

    override var tintColor: UIColor! {
        didSet {
            underline?.backgroundColor = tintColor
            setTitleColor(tintColor, for: .selected)
        }
    }
}
