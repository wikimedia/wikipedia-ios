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

        guard WMFDeveloperSettingsDataController.shared.showGamesV1 else {
            moc.perform {
                self.removeAllContent(in: moc)
                completion?()
            }
            return
        }

        guard let languageCode = siteURL.wmf_languageCode else {
            completion?()
            return
        }

        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
        let today = Self.todayDateString()

        let siteURL = self.siteURL
        Task {
            do {
                let gamesController = WMFGamesDataController()
                let isAvailable = try await gamesController.isWhichCameFirstDailySessionAvailable(date: today, project: project)
                guard isAvailable else {
                    completion?()
                    return
                }

                // Encode preview events as JSON Data so the cell can configure its layout
                // synchronously without any async fetch. The OTD response is already cached
                // from the isWhichCameFirstDailySessionAvailable check above.
                var encodedPreview: Data?
                if let preview = try? await gamesController.fetchWhichCameFirstDailyPreviewEvents(date: today, project: project) {
                    let events = [preview.optionA, preview.optionB]
                    encodedPreview = try? JSONEncoder().encode(events)
                }

                await moc.perform {
                    guard let url = WMFContentGroup.dailyGameURL(forSiteURL: siteURL) else {
                        completion?()
                        return
                    }
                    moc.fetchOrCreateGroup(for: url, of: .dailyGame, for: Date(), withSiteURL: siteURL, associatedContent: encodedPreview as NSData?, customizationBlock: nil)
                    completion?()
                }
            } catch {
                completion?()
            }
        }
    }

    func removeAllContent(in moc: NSManagedObjectContext) {
        guard let url = WMFContentGroup.dailyGameURL(forSiteURL: siteURL) else { return }
        if let group = moc.contentGroup(for: url) {
            moc.remove(group)
        }
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
