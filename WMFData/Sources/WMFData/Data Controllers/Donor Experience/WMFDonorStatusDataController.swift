import Foundation

/// The donor relationship that a reader consented to on the web. The codes are the ones of the
/// `wikimedia-donor` user preference, from the WikimediaCustomizations extension. The app only
/// reads them. It never writes the preference.
public enum WMFDonorCode: Int, Sendable {
    case none = 0
    case recent = 1
    case sustaining = 2
    case lapsed = 3
    case returning = 4
    case contactable = 5

    /// True when the relationship counts as a recent donation. Lapsed and contactable readers did
    /// not donate recently. The same codes count on Android.
    public var isRecentDonor: Bool {
        switch self {
        case .recent, .sustaining, .returning:
            return true
        case .none, .lapsed, .contactable:
            return false
        }
    }
}

/// The content of the `wikimedia-donor` preference of a reader who consented to the donor
/// recognition on the web.
public struct WMFWebDonorStatus: Sendable, Equatable {
    /// `nil` when the preference has a code that the app does not know.
    public let code: WMFDonorCode?
    public let source: String?

    public var isRecentDonor: Bool {
        code?.isRecentDonor == true
    }
}

/// Reads the donor status that a logged-in reader consented to on the web. Year in Review uses it
/// to recognize a donor who did not donate in the app.
public final class WMFDonorStatusDataController: Sendable {

    static let preferenceName = "wikimedia-donor"

    private let mediaWikiService: WMFService?

    public init(mediaWikiService: WMFService? = WMFDataEnvironment.current.mediaWikiService) {
        self.mediaWikiService = mediaWikiService
    }

    /// The web donor status of the logged-in reader on `project`. `nil` when the reader did not
    /// consent to the donor recognition: then the preference is empty.
    /// - Throws: When the request fails or the reader is not logged in.
    public func fetchWebDonorStatus(project: WMFProject) async throws -> WMFWebDonorStatus? {
        guard let mediaWikiService else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }

        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }

        let parameters: [String: Any] = [
            "action": "query",
            "meta": "userinfo",
            "uiprop": "options",
            "assert": "user",
            "format": "json",
            "errorformat": "html"
        ]

        let request = WMFMediaWikiServiceRequest(url: url, method: .GET, backend: .mediaWiki, parameters: parameters)

        let response: UserInfoOptionsResponse = try await withCheckedThrowingContinuation { continuation in
            mediaWikiService.performDecodableGET(request: request) { (result: Result<UserInfoOptionsResponse, Error>) in
                continuation.resume(with: result)
            }
        }

        // The API reports its errors in the body of a 200 response.
        if let error = response.errors?.first {
            throw WMFDataControllerError.mediaWikiResponseError(error)
        }

        guard let preference = response.query?.userinfo?.options?.wikimediaDonor else {
            throw WMFDataControllerError.unexpectedResponse
        }

        return Self.webDonorStatus(fromPreference: preference)
    }

    /// Parses the `wikimedia-donor` preference. It is a JSON object in a string, for example
    /// `{"source":"reader-donor-account","value":1,"timestamp":1760000000}`, or an empty string when
    /// the reader did not consent.
    /// - Returns: `nil` for an empty preference. A preference that does not parse is a status
    ///   without a code, so it does not count as a donor.
    public static func webDonorStatus(fromPreference preference: String) -> WMFWebDonorStatus? {
        guard !preference.isEmpty else {
            return nil
        }

        guard let data = preference.data(using: .utf8),
              let payload = try? JSONDecoder().decode(DonorPreferencePayload.self, from: data) else {
            return WMFWebDonorStatus(code: nil, source: nil)
        }

        return WMFWebDonorStatus(code: payload.value.flatMap(WMFDonorCode.init(rawValue:)), source: payload.source)
    }

    // MARK: - Response models

    private struct DonorPreferencePayload: Decodable {
        let value: Int?
        let source: String?

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            // The sync script stores the code as an integer. Accept a string too, in case a
            // future writer encodes it that way.
            if let value = try? container.decodeIfPresent(Int.self, forKey: .value) {
                self.value = value
            } else if let text = try? container.decodeIfPresent(String.self, forKey: .value) {
                self.value = Int(text)
            } else {
                self.value = nil
            }
            self.source = try? container.decodeIfPresent(String.self, forKey: .source)
        }

        private enum CodingKeys: String, CodingKey {
            case value
            case source
        }
    }

    private struct UserInfoOptionsResponse: Decodable {
        let query: Query?
        let errors: [WMFMediaWikiError]?

        struct Query: Decodable {
            let userinfo: UserInfo?
        }

        struct UserInfo: Decodable {
            let options: Options?
        }

        /// The options have many keys of mixed types. Only the donor preference is decoded.
        struct Options: Decodable {
            let wikimediaDonor: String?

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: DynamicCodingKey.self)
                let key = DynamicCodingKey(stringValue: WMFDonorStatusDataController.preferenceName)
                // A missing or null preference is the default, which is empty.
                wikimediaDonor = (try? container.decodeIfPresent(String.self, forKey: key)) ?? ""
            }
        }

        struct DynamicCodingKey: CodingKey {
            let stringValue: String
            let intValue: Int? = nil

            init(stringValue: String) {
                self.stringValue = stringValue
            }

            init?(intValue: Int) {
                nil
            }
        }
    }
}
