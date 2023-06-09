import Foundation

extension String {
    var localized: String {
        NSLocalizedString(self, bundle: Bundle(identifier: "org.wikimedia.WikipediaUnitTests")! ,comment: "")
    }
}
