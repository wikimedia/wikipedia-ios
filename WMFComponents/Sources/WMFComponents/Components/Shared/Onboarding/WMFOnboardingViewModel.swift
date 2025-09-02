import UIKit

public struct WMFOnboardingViewModel {

    // MARK: - Properties

    var title: String
    var cells: [WMFOnboardingCellViewModel]
    var primaryButtonTitle: String
    var secondaryButtonTitle: String?
    var secondaryButtonTrailingIcon: UIImage?
    var primaryButtonAction: (() -> Void)?
    var secondaryButtonAction: (() -> Void)?

    // MARK: - Lifecycle

    public init(title: String, cells: [WMFOnboardingCellViewModel], primaryButtonTitle: String, secondaryButtonTitle: String?, secondaryButtonTrailingIcon: UIImage? = nil, primaryButtonAction: (() -> Void)? = nil, secondaryButtonAction: (() -> Void)? = nil) {
        self.title = title
        self.cells = cells
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
        self.secondaryButtonTrailingIcon = secondaryButtonTrailingIcon
        self.primaryButtonAction = primaryButtonAction
        self.secondaryButtonAction = secondaryButtonAction
    }

    public struct WMFOnboardingCellViewModel {
        var icon: UIImage?
        var title: String
        var subtitle: String?
		var fillIconBackground: Bool
        var tintBlue: Bool

        public init(icon: UIImage?, title: String, subtitle: String?, fillIconBackground: Bool = false, tintBlue: Bool = false) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
			self.fillIconBackground = fillIconBackground
            self.tintBlue = tintBlue
        }
    }
}
