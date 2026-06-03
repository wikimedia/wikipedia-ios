import Foundation
import CoreData

public class WMFGamesDataController {

    // MARK: - Nested Types

    public enum CustomError: Error {
        case missingContext
        case missingSelf
        case missingIdentifier
        case missingProject
        case missingContentData
        case sessionNotFound
        case invalidPickedOption
        case insufficientQuestions
    }

    // MARK: - Properties

    private var _backgroundContext: NSManagedObjectContext?
    private var backgroundContext: NSManagedObjectContext? {
        if _backgroundContext == nil {
            _backgroundContext = try? coreDataStore?.newBackgroundContext
            _backgroundContext?.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
        return _backgroundContext
    }

    private var _coreDataStore: WMFCoreDataStore?
    private var coreDataStore: WMFCoreDataStore? {
        return _coreDataStore ?? WMFDataEnvironment.current.coreDataStore
    }

    // MARK: - Lifecycle

    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore) {
        self._coreDataStore = coreDataStore
    }

    // MARK: - Game-Agnostic Methods

    private func fetchSession(gameType: String, project: WMFProject, dailyGameDate: String? = nil) async throws -> WMFGameSession? {
        let projectID = project.id
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }

        return try await moc.perform { [self] in
            let predicate: NSPredicate
            if let dailyGameDate {
                predicate = NSPredicate(format: "gameType == %@ AND projectID == %@ AND dailyGameDate == %@", gameType, projectID, dailyGameDate)
            } else {
                predicate = NSPredicate(format: "gameType == %@ AND projectID == %@ AND dailyGameDate == nil", gameType, projectID)
            }
            guard let cdSession = try self.coreDataStore?.fetch(entityType: CDGameSession.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
                return nil
            }
            return try self.gameSession(from: cdSession)
        }
    }

    private func createSession(gameType: String, project: WMFProject, dailyGameDate: String? = nil, contentData: Data) async throws -> WMFGameSession {
        let projectID = project.id
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }

        return try await moc.perform { [self] in
            let cdSession = try coreDataStore.create(entityType: CDGameSession.self, in: moc)
            cdSession.identifier = UUID()
            cdSession.gameType = gameType
            cdSession.projectID = projectID
            cdSession.dailyGameDate = dailyGameDate
            cdSession.status = WMFGameSessionStatus.inProgress.rawValue
            cdSession.contentData = contentData
            cdSession.currentQuestionIndex = 0
            cdSession.score = 0

            try coreDataStore.saveIfNeeded(moc: moc)
            return try self.gameSession(from: cdSession)
        }
    }

    private func fetchSessions(gameType: String, project: WMFProject) async throws -> [WMFGameSession] {
        let projectID = project.id
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }

        return try await moc.perform { [self] in
            let predicate = NSPredicate(format: "gameType == %@ AND projectID == %@", gameType, projectID)
            let sortDescriptors = [NSSortDescriptor(key: "dailyGameDate", ascending: false)]
            let cdSessions = try self.coreDataStore?.fetch(entityType: CDGameSession.self, predicate: predicate, fetchLimit: nil, sortDescriptors: sortDescriptors, in: moc) ?? []
            return try cdSessions.map { try self.gameSession(from: $0) }
        }
    }

    // MARK: - Private Conversion

    private func gameSession(from cdSession: CDGameSession) throws -> WMFGameSession {
        guard let identifier = cdSession.identifier else {
            throw CustomError.missingIdentifier
        }
        guard let contentData = cdSession.contentData else {
            throw CustomError.missingContentData
        }
        guard let gameType = cdSession.gameType,
              let projectID = cdSession.projectID else {
            throw CustomError.missingIdentifier
        }

        guard let project = WMFProject(id: projectID) else {
            throw CustomError.missingProject
        }

        let status = WMFGameSessionStatus(rawValue: cdSession.status) ?? .inProgress

        return WMFGameSession(
            identifier: identifier,
            gameType: gameType,
            project: project,
            dailyGameDate: cdSession.dailyGameDate,
            status: status,
            completedDate: cdSession.completedDate,
            currentQuestionIndex: cdSession.currentQuestionIndex,
            score: cdSession.score,
            contentData: contentData
        )
    }
}

// MARK: - Which Came First

extension WMFGamesDataController {

    public struct WMFWhichCameFirstStats: Sendable {
        public let gamesPlayed: Int
        public let currentStreak: Int
        public let bestStreak: Int
        public let averageScore: Double
    }

    public func fetchWhichCameFirstStats(project: WMFProject) async throws -> WMFWhichCameFirstStats {
        let sessions = try await fetchSessions(gameType: Self.whichCameFirstGameType, project: project)
        let completed = sessions.filter { $0.status == .completed }

        let gamesPlayed = completed.count
        let totalScore = completed.reduce(0) { $0 + Int($1.score) }
        let averageScore: Double? = gamesPlayed > 0 ? {
            let raw = Double(totalScore) / Double(gamesPlayed)
            let rounded = (raw * 10).rounded() / 10
            return rounded
        }() : nil

        let sorted = completed
            .compactMap { session -> (date: String, score: Int32)? in
                guard let date = session.dailyGameDate else { return nil }
                return (date: date, score: session.score)
            }
            .sorted { $0.date < $1.date }

        var bestStreak = 0
        var currentStreak = 0
        var previousDate: String? = nil

        let formatter = DateFormatter.onThisDayAPIDateFormatter

        for entry in sorted {
            if let prev = previousDate,
               let prevDate = formatter.date(from: prev),
               let entryDate = formatter.date(from: entry.date),
               let dayAfterPrev = Calendar.current.date(byAdding: .day, value: 1, to: prevDate),
               Calendar.current.isDate(dayAfterPrev, inSameDayAs: entryDate) {
                currentStreak += 1
            } else {
                currentStreak = 1
            }
            bestStreak = max(bestStreak, currentStreak)
            previousDate = entry.date
        }

        if let lastDate = sorted.last?.date,
           let last = DateFormatter.onThisDayAPIDateFormatter.date(from: lastDate) {
            let today = Date()
            let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
            let lastDay = Calendar.current.startOfDay(for: last)
            if !Calendar.current.isDate(lastDay, inSameDayAs: today) &&
               !Calendar.current.isDate(lastDay, inSameDayAs: yesterday) {
                currentStreak = 0
            }
        } else {
            currentStreak = 0
        }

        return WMFWhichCameFirstStats(
            gamesPlayed: gamesPlayed,
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            averageScore: averageScore ?? 0.0
        )
    }

    public struct WMFWhichCameFirstAnswerResult: Sendable {
        public let isCorrect: Bool
        public let correctAnswer: String
    }

    static let whichCameFirstGameType = "which-came-first"
    public static let whichCameFirstQuestionCount = 5

    // MARK: - Games Announcement

    /// Expiration date for the games announcement (July 1, 2026 UTC).
    private static var gamesAnnouncementExpirationDate: Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 9
        components.day = 1
        return Calendar.current.date(from: components) ?? Date.distantPast
    }

    private var hasSeenGamesAnnouncement: Bool {
        get { UserDefaults.standard.bool(forKey: WMFUserDefaultsKey.hasSeenGamesAnnouncement.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: WMFUserDefaultsKey.hasSeenGamesAnnouncement.rawValue) }
    }

    public func markGamesAnnouncementSeen() {
        hasSeenGamesAnnouncement = true
    }

    public func resetAnnouncementSeen() {
        hasSeenGamesAnnouncement = false
    }

    /// Returns true if the games announcement should be shown.
    /// Checks: not yet seen, not past expiration, games feature enabled, and game available in at least one app language.
    public func shouldShowGamesAnnouncement(date: String) async -> Bool {
        guard !hasSeenGamesAnnouncement else { return false }
        guard let parsedDate = DateFormatter.onThisDayAPIDateFormatter.date(from: date),
              parsedDate < Self.gamesAnnouncementExpirationDate else { return false }

        let appLanguages = WMFDataEnvironment.current.appData.appLanguages
        guard !appLanguages.isEmpty else { return false }

        for language in appLanguages {
            let project = WMFProject.wikipedia(language)
            if (try? await isWhichCameFirstDailySessionAvailable(date: date, project: project)) == true {
                return true
            }
        }
        return false
    }

    public func isWhichCameFirstDailySessionAvailable(date: String, project: WMFProject, onThisDayDataController: WMFOnThisDayDataController = WMFOnThisDayDataController.shared) async throws -> Bool {
        if try await fetchSession(gameType: Self.whichCameFirstGameType, project: project, dailyGameDate: date) != nil {
            return true
        }

        let components = date.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            return false
        }

        let response = try await onThisDayDataController.fetchOnThisDay(project: project, month: month, day: day)
        let questions = Self.makeWhichCameFirstQuestions(from: response.events, month: month, day: day, count: Self.whichCameFirstQuestionCount)
        return questions.count == Self.whichCameFirstQuestionCount
    }

    public func fetchOrStartWhichCameFirstDailySession(
        date: String,
        project: WMFProject,
        onThisDayDataController: WMFOnThisDayDataController = WMFOnThisDayDataController.shared
    ) async throws -> (WMFWhichCameFirstGameState, UUID) {
        if let existingSession = try await fetchSession(gameType: Self.whichCameFirstGameType, project: project, dailyGameDate: date) {
            let gameState = try decodeWhichCameFirstGameState(from: existingSession.contentData)
            return (gameState, existingSession.identifier)
        }

        let components = date.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2]) else {
            throw CustomError.missingIdentifier
        }

        let response = try await onThisDayDataController.fetchOnThisDay(project: project, month: month, day: day)
        let questions = Self.makeWhichCameFirstQuestions(from: response.events, month: month, day: day, count: Self.whichCameFirstQuestionCount)

        guard questions.count == Self.whichCameFirstQuestionCount else {
            throw CustomError.insufficientQuestions
        }

        let gameState = WMFWhichCameFirstGameState(questions: questions)

        let contentData = try encodeWhichCameFirstGameState(gameState)
        let session = try await createSession(gameType: Self.whichCameFirstGameType, project: project, dailyGameDate: date, contentData: contentData)
        return (gameState, session.identifier)
    }

    private static func makeWhichCameFirstQuestions(from events: [WMFOnThisDayEvent], month: Int, day: Int, count: Int) -> [WMFWhichCameFirstQuestion] {
        let calendar = Calendar(identifier: .gregorian)
        var pool = events.filter { !$0.pages.isEmpty }.sorted { $0.year < $1.year }
        var questions: [WMFWhichCameFirstQuestion] = []

        func makeDate(year: Int) -> Date {
            var components = DateComponents()
            components.year = year
            components.month = month
            components.day = day
            return calendar.date(from: components) ?? Date()
        }

        while questions.count < count && !pool.isEmpty {
            let event1 = pool.removeFirst()

            let yearSpread = max(Int((390.0 - 0.19043 * Double(event1.year))), 5)
            let partner = pool.first(where: { abs(event1.year - $0.year) <= yearSpread })
                ?? pool.min(by: { abs(event1.year - $0.year) < abs(event1.year - $1.year) })

            guard let event2 = partner, event2.year != event1.year else { continue }
            pool.removeAll { $0.year == event2.year && $0.text == event2.text }

            let page1 = event1.pages.first
            let thumbnail1 = event1.pages.first(where: { $0.thumbnail?.source != nil })?.thumbnail?.source
            let page2 = event2.pages.first
            let thumbnail2 = event2.pages.first(where: { $0.thumbnail?.source != nil })?.thumbnail?.source

            let optionA = WMFWhichCameFirstEvent(
                title: event1.text,
                date: makeDate(year: event1.year),
                articleTitle: page1?.title,
                thumbnailURL: thumbnail1
            )
            let optionB = WMFWhichCameFirstEvent(
                title: event2.text,
                date: makeDate(year: event2.year),
                articleTitle: page2?.title,
                thumbnailURL: thumbnail2
            )

            let flip = Bool.random()
            questions.append(WMFWhichCameFirstQuestion(
                optionA: flip ? optionB : optionA,
                optionB: flip ? optionA : optionB,
                correctAnswer: flip ? "B" : "A"
            ))
        }

        return questions
    }

    public func submitWhichCameFirstAnswer(sessionIdentifier: UUID, questionIdentifier: UUID, pickedOption: String) async throws -> WMFWhichCameFirstAnswerResult {
        guard pickedOption == "A" || pickedOption == "B" else {
            throw CustomError.invalidPickedOption
        }

        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }

        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }

        return try await moc.perform { [self] in
            let predicate = NSPredicate(format: "identifier == %@", sessionIdentifier as CVarArg)
            guard let cdSession = try self.coreDataStore?.fetch(entityType: CDGameSession.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
                throw CustomError.sessionNotFound
            }

            guard let existingData = cdSession.contentData else {
                throw CustomError.missingContentData
            }

            var gameState = try self.decodeWhichCameFirstGameState(from: existingData)

            guard let question = gameState.questions.first(where: { $0.id == questionIdentifier }) else {
                throw CustomError.sessionNotFound
            }

            let isCorrect = pickedOption == question.correctAnswer
            gameState.answers[questionIdentifier.uuidString] = pickedOption

            let answeredCount = Int32(gameState.answers.count)
            let correctCount = Int32(gameState.questions.filter { q in
                gameState.answers[q.id.uuidString] == q.correctAnswer
            }.count)

            cdSession.contentData = try self.encodeWhichCameFirstGameState(gameState)
            cdSession.currentQuestionIndex = answeredCount
            cdSession.score = correctCount

            let allAnswered = answeredCount == Int32(gameState.questions.count)
            if allAnswered {
                cdSession.status = WMFGameSessionStatus.completed.rawValue
                cdSession.completedDate = Date()
            }

            try coreDataStore.saveIfNeeded(moc: moc)

            let result = WMFWhichCameFirstAnswerResult(isCorrect: isCorrect, correctAnswer: question.correctAnswer)

            let projectID = cdSession.projectID ?? ""
            let dailyGameDate = cdSession.dailyGameDate ?? ""
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: WMFNSNotification.whichCameFirstSessionDidUpdate,
                    object: nil,
                    userInfo: ["projectID": projectID, "dailyGameDate": dailyGameDate]
                )
            }

            return result
        }
    }

    public func fetchWhichCameFirstDailySession(date: String, project: WMFProject) async throws -> WMFGameSession? {
        return try await fetchSession(gameType: Self.whichCameFirstGameType, project: project, dailyGameDate: date)
    }

    public func fetchWhichCameFirstDailyPreviewEvents(
        date: String,
        project: WMFProject,
        onThisDayDataController: WMFOnThisDayDataController = WMFOnThisDayDataController.shared
    ) async throws -> (optionA: WMFWhichCameFirstEvent, optionB: WMFWhichCameFirstEvent)? {
        if let session = try await fetchSession(gameType: Self.whichCameFirstGameType, project: project, dailyGameDate: date) {
            let gameState = try decodeWhichCameFirstGameState(from: session.contentData)
            guard let first = gameState.questions.first else { return nil }
            return (first.optionA, first.optionB)
        }

        let components = date.split(separator: "-")
        guard components.count == 3,
              let month = Int(components[1]),
              let day = Int(components[2]) else { return nil }

        let response = try await onThisDayDataController.fetchOnThisDay(project: project, month: month, day: day)
        let questions = Self.makeWhichCameFirstQuestions(from: response.events, month: month, day: day, count: 1)
        guard let first = questions.first else { return nil }
        return (first.optionA, first.optionB)
    }

    public func fetchWhichCameFirstSessions(project: WMFProject) async throws -> [WMFGameSession] {
        return try await fetchSessions(gameType: Self.whichCameFirstGameType, project: project)
    }

    public func clearAllSessions() async throws {
        guard let moc = backgroundContext else {
            throw CustomError.missingContext
        }
        try await moc.perform { [self] in
            let sessions = try self.coreDataStore?.fetch(entityType: CDGameSession.self, predicate: nil, fetchLimit: nil, in: moc) ?? []
            for session in sessions {
                moc.delete(session)
            }
            try moc.save()
            NotificationCenter.default.post(name: WMFNSNotification.gamesAllSessionsCleared, object: nil)
        }
    }

    // MARK: - Private Encoding Helpers

    private func decodeWhichCameFirstGameState(from data: Data) throws -> WMFWhichCameFirstGameState {
        return try JSONDecoder().decode(WMFWhichCameFirstGameState.self, from: data)
    }

    private func encodeWhichCameFirstGameState(_ gameState: WMFWhichCameFirstGameState) throws -> Data {
        return try JSONEncoder().encode(gameState)
    }
}
