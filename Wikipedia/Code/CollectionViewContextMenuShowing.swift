import Foundation
import UIKit

protocol CollectionViewContextMenuShowing {
    func previewingViewController(for indexPath: IndexPath, at location: CGPoint) -> UIViewController?
    // only need this if some aren't article VCs
    func previewActions(for indexPath: IndexPath) -> [UIMenuElement]?
    var poppingIntoVCCompletion: () -> Void { get }
}
