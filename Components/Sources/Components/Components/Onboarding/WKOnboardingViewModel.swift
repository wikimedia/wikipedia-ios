import UIKit

public struct WKOnboardingViewModel {

    // MARK: - Properties

    var title: String
    var cells: [WKOnboardingCellViewModel]
    var primaryButtonTitle: String
    var secondaryButtonTitle: String?

    // MARK: - Lifecycle

    public init(title: String, cells: [WKOnboardingCellViewModel], primaryButtonTitle: String, secondaryButtonTitle: String?) {
        self.title = title
        self.cells = cells
        self.primaryButtonTitle = primaryButtonTitle
        self.secondaryButtonTitle = secondaryButtonTitle
    }

    public struct WKOnboardingCellViewModel {
        var icon: UIImage?
        var title: String
        var subtitle: String?

        public init(icon: UIImage?, title: String, subtitle: String?) {
            self.icon = icon
            self.title = title
            self.subtitle = subtitle
        }
    }
}
