import Foundation

public protocol ClientDataCallback {
    func getAgentData() -> AgentData?
    func getMediawikiData() -> MediawikiData?
    func getPerformerData() -> PerformerData?
}
