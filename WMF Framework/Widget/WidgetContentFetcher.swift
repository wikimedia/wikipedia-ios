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

	let session = Session(configuration: .current)

	// From supported language list at https://www.mediawiki.org/wiki/Wikifeeds
	private let supportedFeaturedArticleLanguageCodes = ["bg", "bn", "bs", "cs", "de", "el", "en", "fa", "he", "hu", "ja", "la", "no", "sco", "sd", "sv", "ur", "vi", "zh"]

	// MARK: - Public - Featured Article Widget

	public func fetchFeaturedContent(forDate date: Date, siteURL: URL, languageCode: String, languageVariantCode: String? = nil, completion: @escaping (FeaturedContentResult) -> Void) {
		guard supportedFeaturedArticleLanguageCodes.contains(languageCode) else {
			completion(.failure(.unsupportedLanguage))
			return
		}
		
		var featuredURL = WMFFeedContentFetcher.feedContentURL(forSiteURL: siteURL, on: date, configuration: .current)
		featuredURL.wmf_languageVariantCode = languageVariantCode
		
		let task = session.dataTask(with: featuredURL) { data, _, error in
			if let data = data, var decoded = try? JSONDecoder().decode(WidgetFeaturedContent.self, from: data) {
				decoded.fetchDate = Date()
				completion(.success(decoded))
			} else {
				completion(.failure(.contentFailure))
			}
		}

		guard let dataTask = task else {
			completion(.failure(.urlFailure))
			return
		}

		dataTask.resume()
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

		guard let dataTask = task else {
			completion(.failure(.urlFailure))
			return
		}

		dataTask.resume()
	}

}
