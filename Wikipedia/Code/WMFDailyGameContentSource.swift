import Foundation
import WMFData

/// Content source for the "Which Came First?" daily game Explore card.
/// Creates a content group only when the game is available for today's date.
@objc(WMFDailyGameContentSource)
final class WMFDailyGameContentSource: NSObject, WMFContentSource {

    private let dataStore: MWKDataStore
    private let siteURL: URL

    @objc init(dataStore: MWKDataStore, siteURL: URL) {
        self.dataStore = dataStore
        self.siteURL = siteURL
        super.init()
    }

    // MARK: - WMFContentSource

    func loadNewContent(in moc: NSManagedObjectContext, force: Bool, completion: (() -> Void)?) {

        moc.perform {
            self.removeAllContent(in: moc)
        }

        guard let languageCode = siteURL.wmf_languageCode else {
            completion?()
            return
        }

        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
        let today = Self.todayDateString()

        Task {
            do {
                let isAvailable = try await WMFGamesDataController().isWhichCameFirstDailySessionAvailable(date: today, project: project)
                guard isAvailable else {
                    completion?()
                    return
                }
                await moc.perform {
                    guard let url = WMFContentGroup.dailyGameURL(forSiteURL: self.siteURL) else {
                        completion?()
                        return
                    }
                    moc.fetchOrCreateGroup(for: url, of: .dailyGame, for: Date(), withSiteURL: self.siteURL, associatedContent: nil, customizationBlock: nil)
                    completion?()
                }
            } catch {
                completion?()
            }
        }
    }

    func removeAllContent(in moc: NSManagedObjectContext) {
        moc.removeAllContentGroups(of: .dailyGame)
    }

    // MARK: - Helpers

    private static func todayDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "UTC")
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: Date())
    }
}
