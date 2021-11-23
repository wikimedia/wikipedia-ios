import UIKit

/// A `UILabel` embedded within a `UIView` to allow easier styling
class InsetLabelView: SetupView {

	// MARK: - Properties

	let label: UILabel = UILabel()

	var insets: NSDirectionalEdgeInsets = .zero {
		didSet {
			labelLeadingAnchor?.constant = insets.leading
			labelTrailingAnchor?.constant = insets.trailing
			labelTopAnchor?.constant = insets.top
			labelBottomAnchor?.constant = insets.bottom
		}
	}

	fileprivate var labelLeadingAnchor: NSLayoutConstraint?
	fileprivate var labelTrailingAnchor: NSLayoutConstraint?
	fileprivate var labelTopAnchor: NSLayoutConstraint?
	fileprivate var labelBottomAnchor: NSLayoutConstraint?

	// MARK: - Setup

	override func setup() {
		label.translatesAutoresizingMaskIntoConstraints = false

		addSubview(label)

		labelLeadingAnchor = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.leading)
		labelTrailingAnchor = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: insets.trailing)
		labelTopAnchor = label.topAnchor.constraint(equalTo: topAnchor, constant: insets.top)
		labelBottomAnchor = label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom)

		NSLayoutConstraint.activate(
			[labelLeadingAnchor, labelTrailingAnchor, labelTopAnchor, labelBottomAnchor].compactMap { $0 }
		)
	}

}
