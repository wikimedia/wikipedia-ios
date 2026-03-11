import Foundation

public class Event: Encodable {
    public var schema: String = ""
    public let meta: Meta
    public var timestamp: String?

    public var instrumentName: String?

    public var agentData: AgentData?
    public var mediawikiData: MediawikiData?
    public var performerData: PerformerData?

    public var action: String?
    public var actionSubtype: String?
    public var actionSource: String?
    public var actionContext: String?
    public var elementId: String?
    public var elementFriendlyName: String?

    public var funnelName: String?
    public var funnelEntryToken: String?
    public var funnelEventSequencePosition: Int?

    public var experiment: EventExperiment?

    // Non-encoded properties
    var clientData: ClientData = ClientData()
    var interactionData: InteractionData = InteractionData()

    public init(
        schema: String,
        stream: String,
        dt: String?,
        instrument: InstrumentImpl? = nil,
        clientData: ClientData,
        interactionData: InteractionData
    ) {
        self.meta = Meta(stream: stream)
        self.schema = schema
        self.timestamp = dt
        applyInstrument(instrument)
        applyClientData(clientData)
        applyInteractionData(interactionData)
    }

    public func applyClientData(_ clientData: ClientData) {
        self.clientData = clientData
        agentData = clientData.agentData
        mediawikiData = clientData.mediawikiData
        performerData = clientData.performerData
    }

    func applyInstrument(_ instrument: InstrumentImpl?) {
        guard let instrument else { return }
        self.instrumentName = instrument.name
        if let funnel = instrument.funnel {
            self.funnelName = funnel.name
            self.funnelEntryToken = funnel.token
            self.funnelEventSequencePosition = funnel.sequence
        }
        if let exp = instrument.experiment {
            self.experiment = EventExperiment(
                assigned: exp.group,
                enrolled: exp.name,
                coordinator: exp.coordinator,
                subjectId: exp.subjectId
            )
        }
    }

    func applyInteractionData(_ interactionData: InteractionData) {
        self.interactionData = interactionData
        self.action = interactionData.action
        self.actionContext = interactionData.actionContext
        self.actionSource = interactionData.actionSource
        self.actionSubtype = interactionData.actionSubtype
        self.elementId = interactionData.elementId
        self.elementFriendlyName = interactionData.elementFriendlyName
    }

    // MARK: - Encodable

    enum CodingKeys: String, CodingKey {
        case schema = "$schema"
        case meta
        case timestamp = "dt"
        case instrumentName = "instrument_name"
        case agentData = "agent"
        case mediawikiData = "mediawiki"
        case performerData = "performer"
        case action
        case actionSubtype = "action_subtype"
        case actionSource = "action_source"
        case actionContext = "action_context"
        case elementId = "element_id"
        case elementFriendlyName = "element_friendly_name"
        case funnelName = "funnel_name"
        case funnelEntryToken = "funnel_entry_token"
        case funnelEventSequencePosition = "funnel_event_sequence_position"
        case experiment
    }

    // MARK: - Nested types

    public struct Meta: Encodable {
        public let stream: String
    }

    public struct EventExperiment: Encodable {
        public let assigned: String
        public let enrolled: String
        public let coordinator: String
        public let samplingUnit: String?
        public let subjectId: String?

        public static let coordinatorDefault = "default"
        public static let coordinatorCustom = "custom"
        public static let coordinatorForced = "forced"

        public init(
            assigned: String,
            enrolled: String,
            coordinator: String = EventExperiment.coordinatorDefault,
            samplingUnit: String? = nil,
            subjectId: String? = nil
        ) {
            self.assigned = assigned
            self.enrolled = enrolled
            self.coordinator = coordinator
            self.samplingUnit = samplingUnit
            self.subjectId = subjectId
        }

        enum CodingKeys: String, CodingKey {
            case assigned
            case enrolled
            case coordinator
            case samplingUnit = "sampling_unit"
            case subjectId = "subject_id"
        }
    }
}
