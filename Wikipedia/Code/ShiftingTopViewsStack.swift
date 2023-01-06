import UIKit

class ShiftingTopViewsStack: UIStackView, Themeable {
    
    let data = ShiftingTopViewsData()
    private var shiftingTopViews: [ShiftingTopView] = []
    
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
    
    func addShiftingTopViews(_ views: [ShiftingTopView]) {
        shiftingTopViews.append(contentsOf: views)
        views.forEach { addArrangedSubview($0) }
        
        for view in views {
            view.stackView = self
        }

        setNeedsLayout()
        layoutIfNeeded()
    }

    func apply(theme: Theme) {
        backgroundColor = theme.colors.paperBackground
        arrangedSubviews.forEach({ ($0 as? Themeable)?.apply(theme: theme) })
    }
}
