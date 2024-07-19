import Foundation
import CocoaLumberjackSwift

class ShiftingTopView: SetupView {
    typealias AmountShifted = CGFloat
    
    weak var stackView: ShiftingTopViewsStack?
    let shiftOrder: Int

    init(shiftOrder: Int) {
        self.shiftOrder = shiftOrder
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setup() {
        super.setup()

        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if stackView == nil {
            DDLogWarn("Missing stackView assignment in ShiftingSubview, which could potentially cause incorrect content inset/padding calculations.")
        }
        stackView?.calculateTotalHeight()
    }

    var contentHeight: CGFloat {
        assertionFailure("Must override")
        return 0
    }

    func shift(amount: CGFloat) -> AmountShifted {
        assertionFailure("Must override")
        return 0
    }
}
