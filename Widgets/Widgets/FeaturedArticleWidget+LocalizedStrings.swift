import Foundation
import WMF

extension FeaturedArticleWidget {

	enum LocalizedStrings {
		static let widgetTitle = WMFLocalizedString("featured-widget-title", value:"Featured article", comment: "Text for title of Featured article widget.")
		static let widgetDescription = WMFLocalizedString("featured-widget-description", value:"Discover the best articles on Wikipedia, selected daily by our community.", comment: "Text for description of Featured article widget displayed when adding to home screen.")
		
		static let widgetContentFailure = WMFLocalizedString("featured-widget-content-failure-for-date", value:"A featured article is not available for this date.", comment: "Text displayed when Featured article is not available on the current date.")
		static let widgetLanguageFailure = WMFLocalizedString("featured-widget-language-failure", value: "Your primary Wikipedia language does not support Featured article. You can update your primary Wikipedia in the app’s Settings menu.", comment: "Error message shown when the user's primary language Wikipedia does not support the 'Featured article' feature.")

		static let fromLanguageWikipedia = WMFLocalizedString("featured-widget-from-language-wikipedia", value: "From %1$@ Wikipedia", comment: "Text displayed as Wikipedia source on Featured article widget. %1$@ will be replaced with the language.")
		static let fromWikipediaDefault = WMFLocalizedString("featured-widget-from-wikipedia", value: "From Wikipedia", comment: "Text displayed as Wikipedia source on Featured article widget if language is unavailable.")

		static func fromLanguageWikipediaTextFor(languageCode: String?) -> String {
			guard let languageCode = languageCode, let localizedLanguageString = Locale.current.localizedString(forLanguageCode: languageCode) else {
				return FeaturedArticleWidget.LocalizedStrings.fromWikipediaDefault
			}

			return String.localizedStringWithFormat(FeaturedArticleWidget.LocalizedStrings.fromLanguageWikipedia, localizedLanguageString)
		}
	}

}
