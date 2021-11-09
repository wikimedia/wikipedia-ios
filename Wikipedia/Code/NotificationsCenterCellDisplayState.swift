import Foundation

/// Represents the range of displayable states for Notifications Center cells
enum NotificationsCenterCellDisplayState: CaseIterable {
	case defaultUnread
	case defaultRead
	case editSelectedUnread
	case editSelectedRead
	case editUnselectedRead
	case editUnselectedUnread

	// MARK: - Properties

	var isDefaultDisplay: Bool {
		return self == .defaultRead || self == .defaultUnread
	}

	var isSelectionDisplay: Bool {
		return !isDefaultDisplay
	}

	var isRead: Bool {
		return self == .defaultRead || self == .editSelectedRead || self == .editUnselectedRead
	}

	var isUnread: Bool {
		return !isRead
	}

	var isEditing: Bool {
		return self == .editSelectedRead || self == .editSelectedUnread || self == .editUnselectedRead || self == .editUnselectedUnread
	}

	var isSelected: Bool {
		return self == .editSelectedUnread || self == .editSelectedRead
	}

	var isUnselected: Bool {
		return !isSelected
	}
}
