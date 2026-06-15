import Foundation
import WMFData

/// Content source for the "Which Came First?" daily game Explore card.
/// Creates a content group only when the game is available for today's date.
@objc(WMFDailyGameContentSource)
public final class WMFDailyGameContentSource: NSObject, WMFContentSource {

    private let dataStore: MWKDataStore
    private let siteURL: URL

    /// The WMFProject.id for the wiki this source serves. Used to match incoming notifications.
    @objc var projectID: String? {
        guard let languageCode = siteURL.wmf_languageCode else { return nil }
        return WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: siteURL.wmf_languageVariantCode)).id
    }

    @objc init(dataStore: MWKDataStore, siteURL: URL) {
        self.dataStore = dataStore
        self.siteURL = siteURL
        super.init()
    }

    // MARK: - WMFContentSource

    public func loadNewContent(in moc: NSManagedObjectContext, force: Bool, completion: (() -> Void)?) {
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
                    let groupURL = WMFContentGroup.dailyGameURL(forSiteURL: siteURL)
                    await moc.perform {
                        if let groupURL, let group = moc.contentGroup(for: groupURL) {
                            moc.remove(group)
                        }
                        completion?()
                    }
                    return
                }

                var encodedPreview: Data?
                if let preview = try? await gamesController.fetchWhichCameFirstDailyPreviewEvents(date: today, project: project) {
                    let session = try? await gamesController.fetchWhichCameFirstDailySession(date: today, project: project)
                    let state: WMFDailyGameContentPreview.GameState
                    if let session {
                        state = session.status == .completed
                            ? .completed(score: Int(session.score), totalQuestions: WMFGamesDataController.whichCameFirstQuestionCount)
                            : .inProgress(questionsAnswered: Int(session.currentQuestionIndex), score: Int(session.score))
                    } else {
                        state = .notStarted
                    }
                    let contentPreview = WMFDailyGameContentPreview(optionA: preview.optionA, optionB: preview.optionB, state: state)
                    encodedPreview = try? JSONEncoder().encode(contentPreview)
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
                let groupURL = WMFContentGroup.dailyGameURL(forSiteURL: siteURL)
                await moc.perform {
                    if let groupURL, let group = moc.contentGroup(for: groupURL) {
                        moc.remove(group)
                    }
                    completion?()
                }
            }
        }
    }

    /// Fetches the current session for the given date+project and updates `contentPreview`
    /// on the matching content group so the Explore cell can reconfigure synchronously.
    @objc func updateContentGroupPreviewWithDate(_ date: String, completionHandler: (() -> Void)?) {
        guard let languageCode = siteURL.wmf_languageCode else {
            completionHandler?()
            return
        }
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: siteURL.wmf_languageVariantCode))
        Task {
            await updateContentGroupPreview(date: date, project: project)
            completionHandler?()
        }
    }

    // @MainActor ensures every continuation after an await resumes on the main thread,
    // which is required for safe access to dataStore.viewContext.
    @MainActor
    private func updateContentGroupPreview(date: String, project: WMFProject) async {
        guard let url = WMFContentGroup.dailyGameURL(forSiteURL: siteURL) else { return }

        let gamesController = WMFGamesDataController()
        let session = try? await gamesController.fetchWhichCameFirstDailySession(date: date, project: project)

        // Decode the existing preview events so we can preserve them.
        let moc = dataStore.viewContext
        let existingPreview = await moc.perform {
            (moc.contentGroup(for: url)?.contentPreview as? Data)
                .flatMap { try? JSONDecoder().decode(WMFDailyGameContentPreview.self, from: $0) }
        }
        let optionA = existingPreview?.optionA
        let optionB = existingPreview?.optionB

        let state: WMFDailyGameContentPreview.GameState
        if let session {
            if session.status == .completed {
                state = .completed(score: Int(session.score), totalQuestions: WMFGamesDataController.whichCameFirstQuestionCount)
            } else {
                state = .inProgress(questionsAnswered: Int(session.currentQuestionIndex), score: Int(session.score))
            }
        } else {
            state = .notStarted
        }

        let newPreview = WMFDailyGameContentPreview(optionA: optionA, optionB: optionB, state: state)
        guard let encoded = try? JSONEncoder().encode(newPreview) else { return }

        await moc.perform {
            guard let group = moc.contentGroup(for: url) else { return }
            group.contentPreview = encoded as NSData
            try? moc.save()
        }
    }

    public func removeAllContent(in moc: NSManagedObjectContext) {
        guard let url = WMFContentGroup.dailyGameURL(forSiteURL: siteURL) else { return }
        if let group = moc.contentGroup(for: url) {
            moc.remove(group)
        }
    }

    // MARK: - Helpers

    private static func todayDateString() -> String {
        let formatter = DateFormatter.onThisDayAPIDateFormatter
        return formatter.string(from: Date())
    }
}
