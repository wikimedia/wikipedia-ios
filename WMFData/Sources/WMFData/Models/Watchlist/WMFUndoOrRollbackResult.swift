public struct WMFUndoOrRollbackResult: Codable {
    public let newRevisionID: Int
    public let oldRevisionID: Int
}
