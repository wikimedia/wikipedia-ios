import Foundation
import WMFData

#if DEBUG

public actor WMFMockFeedDataController: WMFFeedDataControlling {

    public struct Call: Sendable {
        public let project: WMFProject
        public let date: Date
    }

    private let response: WMFFeedAPIResponse
    public private(set) var calls: [Call] = []

    public init(response: WMFFeedAPIResponse) {
        self.response = response
    }

    public func fetchFeed(project: WMFProject, date: Date) async throws -> WMFFeedAPIResponse {
        calls.append(Call(project: project, date: date))
        return response
    }
}

#endif
