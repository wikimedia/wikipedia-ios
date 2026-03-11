import Foundation

public struct ClientData {
    public let agentData: AgentData?
    public let mediawikiData: MediawikiData?
    public let performerData: PerformerData?

    public init(
        agentData: AgentData? = nil,
        mediawikiData: MediawikiData? = nil,
        performerData: PerformerData? = nil
    ) {
        self.agentData = agentData
        self.mediawikiData = mediawikiData
        self.performerData = performerData
    }
}
