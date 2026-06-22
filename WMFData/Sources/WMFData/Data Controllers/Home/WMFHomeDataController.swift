import Foundation

public final actor WMFHomeDataController {

    private let feedDataController: any WMFFeedDataControlling

    // Dates for which feed data has been fetched per project, in descending order (most recent first).
    private var fetchedDates: [WMFProject: [Date]] = [:]

    public static let shared = WMFHomeDataController()

    public init(feedDataController: any WMFFeedDataControlling = WMFFeedDataController.shared) {
        self.feedDataController = feedDataController
    }

    // MARK: - Public API

    /// Fetches the Home feed "Community" data for the given date.
    /// Pass `Date()` (the default) to fetch today's data.
    @discardableResult
    public func fetchCommunity(project: WMFProject, date: Date = Date()) async throws -> WMFFeedAPIResponse {
        let response = try await feedDataController.fetchFeed(project: project, date: date)
        recordFetchedDate(date, project: project)
        return response
    }

    /// Fetches the feed data for the day that precedes the earliest date already fetched for the given project.
    /// Callers must have fetched at least one page via `fetchCommunity` before calling this.
    public func fetchPreviousPage(project: WMFProject) async throws -> WMFFeedAPIResponse {
        guard let earliest = fetchedDates[project]?.last else {
            throw WMFHomeDataControllerError.noFetchedDatesAvailable
        }

        let calendar = Calendar(identifier: .gregorian)
        guard let previousDate = calendar.date(byAdding: .day, value: -1, to: earliest) else {
            throw WMFHomeDataControllerError.failureCalculatingPreviousDate
        }

        let response = try await feedDataController.fetchFeed(project: project, date: previousDate)
        recordFetchedDate(previousDate, project: project)
        return response
    }

    // MARK: - Private

    private func recordFetchedDate(_ date: Date, project: WMFProject) {
        let calendar = Calendar(identifier: .gregorian)
        let normalized = calendar.startOfDay(for: date)
        var dates = fetchedDates[project] ?? []
        guard !dates.contains(where: { calendar.isDate($0, inSameDayAs: normalized) }) else { return }
        dates.append(normalized)
        dates.sort(by: >)
        fetchedDates[project] = dates
    }
}

public enum WMFHomeDataControllerError: LocalizedError {
    case noFetchedDatesAvailable
    case failureCalculatingPreviousDate

    public var errorDescription: String? {
        switch self {
        case .noFetchedDatesAvailable:
            return "No feed pages have been fetched yet. Call fetchCommunity first."
        case .failureCalculatingPreviousDate:
            return "Failed to calculate the previous date."
        }
    }
}
