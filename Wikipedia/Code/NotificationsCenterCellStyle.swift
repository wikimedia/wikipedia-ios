import UIKit

/// Provides image, font, and color styles based on theme and notification type
struct NotificationsCenterCellStyle {

	// MARK: - Properties

	let theme: Theme
	let traitCollection: UITraitCollection
	let notificationType: RemoteNotificationType

	// MARK: - Colors

	var cellSeparatorColor: UIColor {
		return theme.colors.tertiaryText.withAlphaComponent(0.5)
	}

	func headerTextColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		guard displayState.isUnread else {
			return theme.colors.secondaryText
		}

		switch notificationType {
		case .welcome, .editMilestone, .translationMilestone(_):
			return theme.colors.primaryText
		case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice:
			return theme.colors.error
		case .failedMention:
			return theme.colors.primaryText
		default:
			return theme.colors.link
		}
	}

	func subheaderTextColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		switch notificationType {
		default:
			return displayState.isUnread ? theme.colors.primaryText : theme.colors.secondaryText
		}
	}

	var messageTextColor: UIColor {
		return theme.colors.secondaryText
	}

	var metadataTextColor: UIColor {
		return theme.colors.secondaryText
	}

	var relativeTimeAgoColor: UIColor {
		return theme.colors.secondaryText
	}

	var projectSourceColor: UIColor {
		return theme.colors.secondaryText
	}

	func leadingImageBackgroundColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
		if displayState.isSelectionDisplay {
			let color = displayState.isSelected ? theme.colors.link : .clear
			return color
		} else if displayState == .defaultRead {
			return theme.colors.secondaryText
		}

		switch notificationType {
		case .editMilestone, .translationMilestone(_), .welcome, .thanks:
			return theme.colors.accent
		case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice:
			return theme.colors.error
		case .failedMention, .editReverted, .userRightsChange:
			return theme.colors.warning
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

		switch notificationType {
		default:
			return UIFont.wmf_font(.headline, compatibleWithTraitCollection: traitCollection)
		}
	}

	func subheaderFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		if displayState.isRead {			
			return UIFont.wmf_font(.subheadline, compatibleWithTraitCollection: traitCollection)
		}

		switch notificationType {
		default:
			return UIFont.wmf_font(.semiboldSubheadline, compatibleWithTraitCollection: traitCollection)
		}
	}

	func messageFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch notificationType {
		default:
			return UIFont.wmf_font(.body, compatibleWithTraitCollection: traitCollection)
		}
	}

	func metadataFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch notificationType {
		default:
			return UIFont.wmf_font(.mediumFootnote, compatibleWithTraitCollection: traitCollection)
		}
	}

	func relativeTimeAgoFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch notificationType {
		default:
			return UIFont.wmf_font(.boldFootnote, compatibleWithTraitCollection: traitCollection)
		}
	}

	func projectSourceFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
		switch notificationType {
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

		if #available(iOS 13.0, *) {
			// Return image for the notification type
			switch notificationType {
			case .userTalkPageMessage:
				return UIImage(named: "notifications-type-user-talk-message")
			case .mentionInTalkPage, .mentionInEditSummary, .successfulMention:
				return UIImage(systemName: "at", withConfiguration: UIImage.SymbolConfiguration(weight: .heavy))
			case .editReverted:
				return UIImage(named: "notifications-type-edit-revert")
			case .userRightsChange:
				return UIImage(named: "notifications-type-user-rights")
			case .pageReviewed:
				return UIImage(named: "notifications-type-page-reviewed")
			case .pageLinked, .connectionWithWikidata:
				return UIImage(systemName: "link", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
			case .thanks:
				return UIImage(named: "notifications-type-thanks")
			case .welcome, .translationMilestone(_), .editMilestone:
				return UIImage(systemName: "heart.fill")
			case .loginFailKnownDevice, .loginFailUnknownDevice, .loginSuccessUnknownDevice:
				return UIImage(named: "notifications-type-login-notify")
			case .emailFromOtherUser:
				return UIImage(systemName: "mail", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold))
			default:
				return UIImage(systemName: "app.badge.fill")
			}
		} else {
			fatalError()
		}
	}

}
