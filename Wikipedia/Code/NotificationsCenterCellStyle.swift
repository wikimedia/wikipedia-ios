import WMFComponents

/// Provides image, font, and color styles based on theme and notification type
struct NotificationsCenterCellStyle {

    // MARK: - Properties

    let theme: Theme
    let traitCollection: UITraitCollection
    let notificationType: RemoteNotificationType

    // MARK: - Colors

    var cellSeparatorColor: UIColor {
        return theme.colors.border
    }

    func textColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
        guard displayState.isUnread else {
            return theme.colors.secondaryText
        }

        return theme.colors.primaryText
    }

    func leadingImageBackgroundColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
        if displayState.isSelectionDisplay {
            let color = displayState.isSelected ? theme.colors.link : .clear
            return color
        }

        return displayState.isUnread
            ? notificationType.imageBackgroundColorWithTheme(theme)
            : notificationType.imageBackgroundColorWithTheme(theme).withAlphaComponent(0.5)
    }

    func leadingImageBorderColor(_ displayState: NotificationsCenterCellDisplayState) -> UIColor {
        if displayState.isSelectionDisplay {
            let color = displayState.isSelected ? theme.colors.link : theme.colors.secondaryText
            return color
        }

        return .clear
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
            return WMFFont.for(.subheadline, compatibleWith: traitCollection)
        }

        return WMFFont.for(.boldSubheadline, compatibleWith: traitCollection)
    }

    func subheaderFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
        if displayState.isRead {
            return WMFFont.for(.footnote, compatibleWith: traitCollection)
        }

        return WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
    }

    var messageFont: UIFont {
        return WMFFont.for(.footnote, compatibleWith: traitCollection)
    }

    func metadataFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
        if displayState.isRead {
            return WMFFont.for(.footnote, compatibleWith: traitCollection)
        }

        return WMFFont.for(.mediumFootnote, compatibleWith: traitCollection)
    }

    func relativeTimeAgoFont(_ displayState: NotificationsCenterCellDisplayState) -> UIFont {
        if displayState.isRead {
            return WMFFont.for(.footnote, compatibleWith: traitCollection)
        }

        return WMFFont.for(.boldFootnote, compatibleWith: traitCollection)
    }

    var projectSourceFont: UIFont {
        return WMFFont.for(.caption1, compatibleWith: traitCollection)
    }

    // MARK: - Images

    func leadingImage(_ displayState: NotificationsCenterCellDisplayState) -> UIImage? {
        guard !displayState.isEditing else {
            let image = displayState.isSelected ? UIImage(named: "notifications-center-checkmark") : nil
            return image
        }
        
        return UIImage(named: notificationType.imageName)
    }

}
