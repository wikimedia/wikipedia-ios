import Foundation
import UIKit

protocol CollectionViewContextMenuShowing {
    func previewingViewController(for indexPath: IndexPath, at location: CGPoint) -> UIViewController?
}
