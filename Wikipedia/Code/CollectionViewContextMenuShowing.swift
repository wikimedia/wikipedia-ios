import Foundation
import UIKit

protocol CollectionViewContextMenuShowing {
    func previewingViewController(for indexPath: IndexPath) -> UIViewController?
    func previewActions(for indexPath: IndexPath) -> [UIMenuElement]?
    var poppingIntoVCCompletion: () -> Void { get }
}
