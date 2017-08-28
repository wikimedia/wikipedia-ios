import UIKit

extension UITableViewCell {
    @objc static func identifier() -> String {
        return String(describing: self)
    }
}
