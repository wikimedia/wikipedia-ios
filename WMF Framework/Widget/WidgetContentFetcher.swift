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

    /// Fetches the day's feed. The diagnostics describe what happened whether or not the result
    /// is a success, so the controller can persist them for the developer settings screen.
    public func fetchFeaturedContent(forDate date: Date, siteURL: URL, languageCode: String, languageVariantCode: String? = nil, completion: @escaping (FeaturedContentResult, WidgetFetchDiagnostics) -> Void) {
        // The Swift feed content fetcher returns an optional URL.
        guard var featuredURL = WMFFeedContentFetcher.feedContentURL(forSiteURL: siteURL, on: date, configuration: .current) else {
            completion(.failure(.urlFailure), WidgetFetchDiagnostics(date: Date(), url: "", outcome: .networkFailure, errorDescription: "Could not build the feed URL"))
            return
        }
        featuredURL.wmf_languageVariantCode = languageVariantCode
        let urlString = featuredURL.absoluteString

        let task = session.dataTask(with: featuredURL) { data, response, error in
            let httpStatusCode = (response as? HTTPURLResponse)?.statusCode

            if let error = error {
                completion(.failure(.contentFailure), WidgetFetchDiagnostics(date: Date(), url: urlString, outcome: .networkFailure, httpStatusCode: httpStatusCode, errorDescription: error.localizedDescription))
                return
            }

            if let httpStatusCode = httpStatusCode, !(200..<300).contains(httpStatusCode) {
                completion(.failure(.contentFailure), WidgetFetchDiagnostics(date: Date(), url: urlString, outcome: .networkFailure, httpStatusCode: httpStatusCode, errorDescription: "HTTP \(httpStatusCode)"))
                return
            }

            guard let data = data, !data.isEmpty else {
                completion(.failure(.contentFailure), WidgetFetchDiagnostics(date: Date(), url: urlString, outcome: .networkFailure, httpStatusCode: httpStatusCode, errorDescription: "Empty response"))
                return
            }

            do {
                var decoded = try JSONDecoder().decode(WidgetFeaturedContent.self, from: data)
                decoded.fetchDate = Date()
                completion(.success(decoded), WidgetFetchDiagnostics(date: Date(), url: urlString, httpStatusCode: httpStatusCode, content: decoded))
            } catch {
                // Only reachable when the payload is not a JSON object at all: the sections
                // themselves are decoded independently and never throw out of the model.
                completion(.failure(.contentFailure), WidgetFetchDiagnostics(date: Date(), url: urlString, outcome: .decodeFailure, httpStatusCode: httpStatusCode, errorDescription: WidgetDecodingErrorDescription.describe(error)))
            }
        }

        guard let dataTask = task else {
            completion(.failure(.urlFailure), WidgetFetchDiagnostics(date: Date(), url: urlString, outcome: .networkFailure, errorDescription: "Could not create the request"))
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
