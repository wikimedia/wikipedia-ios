import UIKit

public struct WMFOnboardingViewModel {

    // MARK: - Properties

    var title: String
    var cells: [WMFOnboardingCellViewModel]
    var primaryButtonTitle: String
    var secondaryButtonTitle: String?

    // MARK: - Lifecycle

    public init(title: String, cells: [WMFOnboardingCellViewModel], primaryButtonTitle: String, secondaryButtonTitle: String?) {
        self.title = title
        self.cells = cells
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
    }

    public struct WMFOnboardingCellViewModel {
        var icon: UIImage?
        var title: String
        var subtitle: String?
		var fillIconBackground: Bool

		public init(icon: UIImage?, title: String, subtitle: String?, fillIconBackground: Bool = false) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
			self.fillIconBackground = fillIconBackground
        }
    }
}
