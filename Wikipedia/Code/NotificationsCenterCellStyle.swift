import UIKit

/// Provides image, font, and color styles based on theme and notification type
struct NotificationsCenterCellStyle {

	// MARK: - Properties

	let theme: Theme
	let traitCollection: UITraitCollection
	let category: RemoteNotificationCategory

	// MARK: - Colors

	var cellSeparatorColor: UIColor {
		return theme.colors.tertiaryText.withAlphaComponent(0.5)
	}

	func headerTextColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch category {
		default:
			return displayState.isUnread ? theme.colors.link : theme.colors.secondaryText
		}
	}

	func subheaderTextColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch category {
		default:
			return displayState.isUnread ? theme.colors.primaryText : theme.colors.secondaryText
		}
	}

	func messageTextColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch category {
		default:
			return displayState.isUnread ? theme.colors.secondaryText : theme.colors.secondaryText
		}
	}

	var metadataTextColor: UIColor {
		return theme.colors.secondaryText
	}

	func relativeTimeAgoColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch category {
		default:
			return displayState.isUnread ? theme.colors.secondaryText : theme.colors.secondaryText
		}
	}

	func projectSourceColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch category {
		default:
			return theme.colors.secondaryText
		}
	}

	func leadingImageBackgroundColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		if displayState.isSelectionDisplay {
			let color = displayState.isSelected ? theme.colors.link : .clear
			return color
		} else if displayState == .defaultRead {
			return theme.colors.secondaryText
		}

		switch category {
		default:
			return theme.colors.link
		}
	}

	func leadingImageBorderColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		if displayState.isSelectionDisplay {
			let color = displayState.isSelected ? theme.colors.link : theme.colors.secondaryText
			return color
		}

		return leadingImageBackgroundColor(displayState)
	}

	var leadingImageTintColor: UIColor {
		return theme.colors.paperBackground
	}

	var selectedCellBackgroundColor: UIColor {
		return theme.colors.batchSelectionBackground
	}

	// MARK: - Fonts

	func headerFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		if displayState.isRead {
			return UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
		}

		switch category {
		default:
			return UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
		}
	}

	func subheaderFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		if displayState.isRead {
			return UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
		}

		switch category {
		default:
			return UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
		}
	}

	func messageFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch category {
		default:
			return UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
		}
	}

	func metadataFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch category {
		default:
			return UIFont.wmf_font(.mediumFootnote, compatibleWithTraitCollection: traitCollection)
		}
	}

	func relativeTimeAgoFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch category {
		default:
			return UIFont.wmf_font(.boldFootnote, compatibleWithTraitCollection: traitCollection)
		}
	}

	func projectSourceFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch category {
		default:
			return UIFont.wmf_font(.caption2, compatibleWithTraitCollection: traitCollection)
		}
	}

	// MARK: - Images

	func leadingImage(_ displayState: NotificationsCenterCellDisplayState) -> UIImage? {
		guard !displayState.isEditing else {
			if #available(iOS 13.0, *) {
				let symbolConfiguration = UIImage.SymbolConfiguration(weight: .bold)
				let image = displayState.isSelected ? UIImage(systemName: "checkmark", withConfiguration: symbolConfiguration) : nil
				return image
			} else {
				return nil
			}
		}

		// Return image for the notification category type
		switch category {
		default:
			if #available(iOS 13.0, *) {
				let image = UIImage(systemName: "bubble.right.fill")
				return image
			} else {
				fatalError()
			}
		}
	}

}
