import Foundation

public class ExperimentImpl {
    public let name: String
    public let group: String
    public let subjectId: String?
    public let isLoggable: (() -> Bool)?
    public let coordinator: String

    public static let coordinatorDefault = "default"
    public static let coordinatorCustom = "custom"
    public static let coordinatorForced = "forced"

    public init(
        name: String,
        group: String,
        subjectId: String? = nil,
        isLoggable: (() -> Bool)? = nil,
        coordinator: String = ExperimentImpl.coordinatorCustom
    ) {
        self.name = name
        self.group = group
        self.subjectId = subjectId
        self.isLoggable = isLoggable
        self.coordinator = coordinator
    }
}
