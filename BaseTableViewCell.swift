import UIKit

@objc(WMFBaseTableViewCell)
class BaseTableViewCell: UITableViewCell {
    static func identifier() -> String {
        return String(describing: self)
    }
}
