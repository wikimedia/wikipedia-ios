import UIKit

@objc protocol SwipeableCell: NSObjectProtocol {
    var isSwiping: Bool { get set }
    var swipeTranslation: CGFloat { get set }
    var swipeTranslationWhenOpen: CGFloat { get }
    var actions: [Action] { get set }
    var actionsView: ActionsView { get }
    var backgroundView: UIView? { get }
    func layoutIfNeeded() // call to layout views after setting swipe translation
    var bounds: CGRect { get }
}
