public struct WKUndoOrRollbackResult: Codable {
    public let newRevisionID: Int
    public let oldRevisionID: Int
}
