import UIKit

@objc protocol SwipeableCell: NSObjectProtocol {
    var isSwiping: Bool { get set }
    var swipeTranslation: CGFloat { get set }
    var swipeTranslationWhenOpen: CGFloat { get }
    var actionsView: CollectionViewCellActionsView { get }
    func layoutIfNeeded() // call to layout views after setting swipe translation
    var bounds: CGRect { get }
}
