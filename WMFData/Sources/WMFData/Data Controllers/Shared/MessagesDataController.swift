import Foundation

public actor MessagesDataController {
    
    public struct APIResponse: Codable, Sendable {

        public struct Query: Codable, Sendable {
            let allmessages: [Message]
        }
        
        public struct Message: Codable, Sendable {
            public let name: String
            public let normalizedname: String
            public let content: String
        }
        
        let query: Query?
    }
    
    public static let shared = MessagesDataController()
    
    public init() {}
    
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
        
        // 1. Lift the callback into a Swift-native async result
        let response: APIResponse = try await withCheckedThrowingContinuation { continuation in
            service.performDecodableGET(request: request) { (result: Result<APIResponse, Error>) in
                continuation.resume(with: result)  // resume(with:) is @Sendable-safe
            }
        }
        
        // 2. Post-process outside the closure — no concurrency boundary issues
        let messages = response.query?.allmessages ?? []
        
        guard parseLinks else {
            return messages
        }
        
        return messages.map { message in
            APIResponse.Message(
                name: message.name,
                normalizedname: message.normalizedname,
                content: Self.convertExternalLink(message.content)
            )
        }
    }
    
    private static func convertExternalLink(_ input: String) -> String {
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
