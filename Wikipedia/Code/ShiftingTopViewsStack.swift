import UIKit

class ShiftingTopViewsStack: UIStackView, Themeable {
    
    let data = ShiftingTopViewsData()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        axis = .vertical
        alignment = .fill
        distribution = .fill
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
    }
}
