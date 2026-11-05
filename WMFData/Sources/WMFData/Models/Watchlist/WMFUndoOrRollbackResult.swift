public struct WMFUndoOrRollbackResult: Codable, Sendable {
    public let newRevisionID: Int
    public let oldRevisionID: Int
}
