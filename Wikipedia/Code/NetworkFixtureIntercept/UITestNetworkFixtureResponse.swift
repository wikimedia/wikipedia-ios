import Foundation

/// Normalized HTTP response returned by the fixture manifest store.
struct UITestNetworkFixtureResponse {
    let statusCode: Int
    let headers: [String: String]
    let body: Data
}
