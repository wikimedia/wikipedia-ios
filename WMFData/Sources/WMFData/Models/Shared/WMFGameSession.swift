import Foundation

public enum WMFGameSessionStatus: Int32, Sendable {
    case inProgress = 0
    case completed = 1
}

public struct WMFGameSession: Sendable {
    public let identifier: UUID
    public let gameType: String
    public let project: WMFProject
    public let dailyGameDate: String?
    public let status: WMFGameSessionStatus
    public let completedDate: Date?
    public let currentQuestionIndex: Int32
    public let score: Int32
    public let contentData: Data
}
