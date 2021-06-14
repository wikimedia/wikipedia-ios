import Foundation

public final class WidgetContentFetcher {

	// MARK: - Nested Types

	public enum FetcherError: Error {
		case urlFailure
		case contentFailure
		case unsupportedLanguage
	}

	public typealias FeaturedContentResult = Result<WidgetFeaturedContent, WidgetContentFetcher.FetcherError>

	// MARK: - Properties

	public static let shared = WidgetContentFetcher()

	let session = URLSession.shared

	// From supported language list at https://www.mediawiki.org/wiki/Wikifeeds
	private let supportedFeaturedArticleLanguageCodes = ["bg", "bn", "bs", "cs", "de", "el", "en", "fa", "he", "hu", "ja", "la", "no", "sco", "sd", "sv", "ur", "vi", "zh"]

	// MARK: - Public - Featured Article Widget

	public func fetchFeaturedContent(forDate date: Date, siteURL: URL, languageCode: String, completion: @escaping (FeaturedContentResult) -> Void) {
		guard supportedFeaturedArticleLanguageCodes.contains(languageCode) else {
			completion(.failure(.unsupportedLanguage))
			return
		}
		
		let featuredURL = WMFFeedContentFetcher.feedContentURL(forSiteURL: siteURL, on: date, configuration: .current)
		let task = session.dataTask(with: featuredURL) { data, _, error in
			if let data = data, let decoded = try? JSONDecoder().decode(WidgetFeaturedContent.self, from: data) {
				completion(.success(decoded))
			} else {
				completion(.failure(.contentFailure))
			}
		}

		task.resume()
	}

	public func fetchImageDataFrom(imageSource: WidgetFeaturedContent.FeaturedArticleContent.ImageSource, completion: @escaping (Result<Data, FetcherError>) -> Void) {
		guard let imageURL = URL(string: imageSource.source) else {
			completion(.failure(.urlFailure))
			return
		}

		let task = session.dataTask(with: imageURL) { data, _, error in
			if let data = data {
				completion(.success(data))
			} else {
				completion(.failure(.contentFailure))
			}
		}

		task.resume()
	}

}
