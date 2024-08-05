import Foundation
import UIKit

public final class WMFErrorViewModel {

    public struct LocalizedStrings {
        let title: String
        let subtitle: String
        let buttonTitle: String

        public init(title: String, subtitle: String, buttonTitle: String) {
            self.title = title
            self.subtitle = subtitle
            self.buttonTitle = buttonTitle
        }
    }

    let localizedStrings: LocalizedStrings
    let image: UIImage?

    public init(localizedStrings: LocalizedStrings, image: UIImage?) {
        self.localizedStrings = localizedStrings
        self.image = image
    }
}
