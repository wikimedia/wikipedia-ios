import Foundation

public final actor WMFExploreDataController {

    private let feedDataController: WMFFeedDataController

    // Dates for which feed data has been fetched, in descending order (most recent first).
    private var fetchedDates: [Date] = []

    public static let shared = WMFExploreDataController()

    public init(feedDataController: WMFFeedDataController = WMFFeedDataController.shared) {
        self.feedDataController = feedDataController
    }

    // MARK: - Public API

    /// Fetches the Explore feed "Community Picks" data for the given date.
    /// Pass `Date()` (the default) to fetch today's data.
    @discardableResult
    public func fetchCommunityPicks(project: WMFProject, date: Date = Date()) async throws -> WMFFeedAPIResponse {
        let response = try await feedDataController.fetchFeed(project: project, date: date)
        recordFetchedDate(date)
        return response
    }

    /// Fetches the feed data for the day that precedes the earliest date already fetched.
    /// Callers must have fetched at least one page via `fetchCommunityPicks` before calling this.
    public func fetchPreviousPage(project: WMFProject) async throws -> WMFFeedAPIResponse {
        guard let earliest = fetchedDates.last else {
            throw WMFExploreDataControllerError.noFetchedDatesAvailable
        }

        let calendar = Calendar(identifier: .gregorian)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: earliest) else {
            throw WMFExploreDataControllerError.failureCalculatingPreviousDate
        }

        let response = try await feedDataController.fetchFeed(project: project, date: previousDate)
        recordFetchedDate(previousDate)
        return response
    }

    // MARK: - Private

    private func recordFetchedDate(_ date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let normalized = calendar.startOfDay(for: date)
        guard !fetchedDates.contains(where: { calendar.isDate($0, inSameDayAs: normalized) }) else { return }
        fetchedDates.append(normalized)
        fetchedDates.sort(by: >)
    }
}

public enum WMFExploreDataControllerError: LocalizedError {
    case noFetchedDatesAvailable
    case failureCalculatingPreviousDate

    public var errorDescription: String? {
        switch self {
        case .noFetchedDatesAvailable:
            return "No feed pages have been fetched yet. Call fetchCommunityPicks first."
        case .failureCalculatingPreviousDate:
            return "Failed to calculate the previous date."
        }
    }
}
