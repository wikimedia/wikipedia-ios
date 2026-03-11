import Foundation

public struct ClientData {
    public let agentData: AgentData?
    public let pageData: PageData?
    public let mediawikiData: MediawikiData?
    public let performerData: PerformerData?

    public init(
        agentData: AgentData? = nil,
        pageData: PageData? = nil,
        mediawikiData: MediawikiData? = nil,
        performerData: PerformerData? = nil
    ) {
        self.agentData = agentData
        self.pageData = pageData
        self.mediawikiData = mediawikiData
        self.performerData = performerData
    }
}
