import Foundation
import WMF

extension TopReadWidget {

	enum LocalizedStrings {
		static let topReadWidgetTitle = WMFLocalizedString("top-read-widget-title", value:"Top read", comment: "Text for title of Top read widget.")
		static let topReadWidgetDescription = WMFLocalizedString("top-read-widget-description", value:"Learn what the world is reading today on Wikipedia.", comment: "Text for description of top read widget displayed when adding to home screen.")
        static let topReadWidgetReadersCountFormat = WMFLocalizedString("top-read-widget-readers-count", value:"%1$@ readers", comment: "Text for displaying the number of readers an article has in the top read widget. %1$@ is replaced with the number of readers.")
	}

}
