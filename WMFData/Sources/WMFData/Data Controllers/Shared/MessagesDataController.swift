import Foundation

public final class MessagesDataController {
    
    public struct APIResponse: Codable {

        public struct Query: Codable {
            let allmessages: [Message]
        }
        
        public struct Message: Codable {
            public let name: String
            public let normalizedname: String
            public let content: String
        }
        
        let query: Query?
    }
    
    public static let shared = MessagesDataController()
    private let service = WMFDataEnvironment.current.mediaWikiService
    
    public init() {}
    
    
    /// Fetches translated messages for a particular wiki
    /// - Parameters:
    ///   - keys: Array of keys to fetch, e.g. "hcaptcha-privacy-policy"
    ///   - parseLinks: true if you need additional client-side parsing of links (more efficient than a followup parse API call).
    ///   - project: Wikimedia project to request from
    /// - Returns: Array of translated message objects for keys.
    ///     For example, if parseLinks = true, it might return `<a href \"https://www.hcaptcha.com/privacy\">Privacy Policy</a>`, if parseLinks = false, it might return `[https://www.hcaptcha.com/privacy Privacy Policy]`
    public func fetchMessages(keys: [String], parseLinks: Bool, project: WMFProject) async throws -> [APIResponse.Message] {
        
        let service = WMFDataEnvironment.current.mediaWikiService
        guard let service else {
            throw WMFDataControllerError.mediaWikiServiceUnavailable
        }
        guard let url = URL.mediaWikiAPIURL(project: project) else {
            throw WMFDataControllerError.failureCreatingRequestURL
        }
        
        let parameters: [String: Any] = [
            "action": "query",
            "meta": "allmessages",
            "ammessages": keys.joined(separator: "|"),
            "format": "json",
            "formatversion": "2"
        ]
        
        let request = WMFMediaWikiServiceRequest(
            url: url,
            method: .GET,
            backend: .mediaWiki,
            parameters: parameters
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<APIResponse, Error>) in
                switch result {
                case .success(let response):
                    guard parseLinks else {
                        continuation.resume(returning: response.query?.allmessages ?? [])
                        return
                    }
                    
                    let parsedMessages = (response.query?.allmessages ?? []).map { message in
                        return APIResponse.Message(name: message.name, normalizedname: message.normalizedname, content: self.convertExternalLink(message.content))
                    }
                    
                    continuation.resume(returning: parsedMessages)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func convertExternalLink(_ input: String) -> String {
        let pattern = #"\[(https?:\/\/[^\s\]]+)\s+([^\]]+)\]"#

        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return input
        }

        let range = NSRange(input.startIndex..., in: input)

        return regex.stringByReplacingMatches(
            in: input,
            range: range,
            withTemplate: #"<a href="$1">$2</a>"#
        )
    }
}
