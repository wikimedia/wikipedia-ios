import UIKit

/// A vertical spacer (conceptually similar to SwiftUI's `Spacer`)
class VerticalSpacerView: SetupView {

	// MARK: - Properties

	var space: CGFloat = 0 {
		didSet {
			spaceHeightAnchor?.constant = space
		}
	}

	fileprivate var spaceHeightAnchor: NSLayoutConstraint?

	// MARK: - Setup

	override func setup() {
		spaceHeightAnchor = heightAnchor.constraint(equalToConstant: space)
		spaceHeightAnchor?.isActive = true
	}

	// MARK: - Factory

	static func spacerWith(space: CGFloat) -> VerticalSpacerView {
		let spacer = VerticalSpacerView()
		spacer.space = space
		return spacer
	}

}
