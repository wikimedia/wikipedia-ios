import Foundation

public struct ExperimentData: Encodable, Sendable {
    public static let coordinatorDefault = "default"
    public static let coordinatorCustom = "custom"
    public static let coordinatorForced = "forced"

    public var enrolled: String
    public var assigned: String
    public var coordinator: String

    public init(
        enrolled: String,
        assigned: String,
        coordinator: String = ExperimentData.coordinatorDefault
    ) {
        self.enrolled = enrolled
        self.assigned = assigned
        self.coordinator = coordinator
    }
}
