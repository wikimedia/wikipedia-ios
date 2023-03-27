import Foundation
import UIKit

/// Header title for list of locations
class HeaderView: UICollectionReusableView {
    
    public lazy var textLabel: UILabel = {
        UILabel.title2
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setConstraints() {
        addConstrained(subview: textLabel, insets: .init(
            top: .zero,
            left: .margin4,
            bottom: .zero,
            right: -.margin4)
        )
    }
}
