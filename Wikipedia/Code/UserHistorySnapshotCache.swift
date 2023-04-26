import Foundation

struct UserHistorySnapshotCache: Codable {

    var snapshot: UserHistoryFunnel.Event

    init(snapshot: UserHistoryFunnel.Event) {
        self.snapshot = snapshot
    }
}
