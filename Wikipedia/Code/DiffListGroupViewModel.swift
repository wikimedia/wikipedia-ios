
import Foundation

//tonitodo: rename since unedited lines isn't really a group
protocol DiffListGroupViewModel {
    var theme: Theme { get set }
    var width: CGFloat { get set }
    var height: CGFloat { get }
    var traitCollection: UITraitCollection { get }
    func updateSize(width: CGFloat, traitCollection: UITraitCollection)
}
