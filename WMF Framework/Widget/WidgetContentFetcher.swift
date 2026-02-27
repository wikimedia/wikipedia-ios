import Foundation

public final class WidgetContentFetcher {

    // MARK: - Nested Types

    public enum FetcherError: Error {
        case urlFailure
        case contentFailure
        case unsupportedLanguage
    }

    public typealias FeaturedContentResult = Result<WidgetFeaturedContent, FetcherError>
    public typealias FeaturedArticleResult = Result<WidgetFeaturedArticle, FetcherError>
    public typealias TopReadResult = Result<WidgetTopRead, FetcherError>
    public typealias PictureOfTheDayResult = Result<WidgetPictureOfTheDay, FetcherError>

    // MARK: - Properties

    public static let shared = WidgetContentFetcher()

    let session = Session(configuration: .current)

    // MARK: - Public - Featured Content

    public func fetchFeaturedContent(forDate date: Date, siteURL: URL, languageCode: String, languageVariantCode: String? = nil, completion: @escaping (FeaturedContentResult) -> Void) {
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

    // MARK: - Public - Utility

    public func fetchImageDataFrom(imageSource: WidgetImageSource, completion: @escaping (Result<Data, FetcherError>) -> Void) {
        guard let imageURL = URL(string: imageSource.source) else {
            completion(.failure(.urlFailure))
            return
        }

        var request = URLRequest(url: imageURL)
        request.setValue(WikipediaAppUtils.versionedUserAgent(), forHTTPHeaderField: "User-Agent")

        let task = session.dataTask(with: request) { data, response, error in
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                completion(.failure(.contentFailure))
                return
            }
            if let data = data, !data.isEmpty {
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
