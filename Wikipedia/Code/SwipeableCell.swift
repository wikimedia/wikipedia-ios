import UIKit

@objc protocol SwipeableCell: NSObjectProtocol {
    var swipeVelocity: CGFloat { get set }
    var isSwiping: Bool { get set }
    var swipeTranslation: CGFloat { get set }
    func openActionPane(_ completion: @escaping (Bool) -> Void)
    func closeActionPane(_ completion: @escaping (Bool) -> Void)
    var actionsView: CollectionViewCellActionsView { get }
}
