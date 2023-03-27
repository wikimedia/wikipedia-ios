import Foundation
import UIKit

extension UILabel {
    static var title: UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title1)
        label.textAlignment = .center
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label.usingConstraints()
    }
    
    static var title2: UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .title2)
        label.textAlignment = .left
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label.usingConstraints()
    }
    
    static var headline: UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .headline)
        label.textAlignment = .left
        label.textColor = .label
        label.adjustsFontForContentSizeCategory = true
        return label.usingConstraints()
    }
    
    static var subheadline: UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textAlignment = .left
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label.usingConstraints()
    }
    
    static var label: UILabel {
        let label = UILabel()
        label.font = .preferredFont(forTextStyle: .caption1)
        label.textAlignment = .left
        label.textColor = .secondaryLabel
        label.adjustsFontForContentSizeCategory = true
        return label.usingConstraints()
    }
    
    func multiline() -> Self {
        numberOfLines = 0
        return self
    }
}
