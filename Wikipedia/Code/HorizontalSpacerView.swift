import UIKit

/// A horizontal spacer (conceptually similar to SwiftUI's `Spacer`)
class HorizontalSpacerView: SetupView {

    // MARK: - Properties

    var space: CGFloat = 0 {
        didSet {
            spaceWidthAnchor?.constant = space
        }
    }

    fileprivate var spaceWidthAnchor: NSLayoutConstraint?

    // MARK: - Setup

    override func setup() {
        spaceWidthAnchor = widthAnchor.constraint(equalToConstant: space)
        spaceWidthAnchor?.isActive = true
    }

    // MARK: - Factory

    static func spacerWith(space: CGFloat) -> HorizontalSpacerView {
        let spacer = HorizontalSpacerView()
        spacer.space = space
        return spacer
    }

}

class FillingHorizontalSpacerView: SetupView {

    // MARK: - Properties

    var space: CGFloat = 0 {
        didSet {
            spaceWidthAnchor?.constant = space
        }
    }

    fileprivate var spaceWidthAnchor: NSLayoutConstraint?

    // MARK: - Setup

    override func setup() {
        spaceWidthAnchor = widthAnchor.constraint(greaterThanOrEqualToConstant: space)
        spaceWidthAnchor?.isActive = true
    }

    // MARK: - Factory

    static func spacerWith(minimumSpace: CGFloat) -> FillingHorizontalSpacerView {
        let spacer = FillingHorizontalSpacerView()
        spacer.space = minimumSpace
        return spacer
    }

}
