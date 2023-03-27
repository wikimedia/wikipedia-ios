import Foundation
import UIKit

extension UIView {
    func usingConstraints() -> Self {
        translatesAutoresizingMaskIntoConstraints = false
        return self
    }
    
    /// Set view as superview with the insets to parent using layout constraints
    func addConstrained(subview: UIView, insets: UIEdgeInsets = .zero) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            subview.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            subview.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            subview.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.right),
            subview.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom)
        ])
    }
}

extension CGFloat {
    static let margin = 4.0
    static let margin2 = margin*2
    static let margin4 = margin*4
    static let margin8 = margin*8
}
