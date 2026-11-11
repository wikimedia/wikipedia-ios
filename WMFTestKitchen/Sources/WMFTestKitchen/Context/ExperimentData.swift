import Foundation

public struct ExperimentData: Encodable, Sendable {
    public static let coordinatorDefault = "default"
    public static let coordinatorCustom = "custom"
    public static let coordinatorForced = "forced"

    public var enrolled: String
    public var assigned: String
    public var coordinator: String
    public var samplingUnit: String?
    public var subjectId: String?

    public init(
        enrolled: String,
        assigned: String,
        coordinator: String = ExperimentData.coordinatorDefault,
        samplingUnit: String? = nil,
        subjectId: String? = nil
    ) {
        self.enrolled = enrolled
        self.assigned = assigned
        self.coordinator = coordinator
        self.samplingUnit = samplingUnit
        self.subjectId = subjectId
    }

    enum CodingKeys: String, CodingKey {
        case enrolled
        case assigned
        case coordinator
        case samplingUnit = "sampling_unit"
        case subjectId = "subject_id"
    }
}
