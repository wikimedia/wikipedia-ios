import Foundation

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

    var contentHeight: CGFloat {
        assertionFailure("Must override")
        return 0
    }

    func shift(amount: CGFloat) -> AmountShifted {
        assertionFailure("Must override")
        return 0
    }
}
