import Foundation

extension EPC {
    public enum Stream: String, Codable {
        case editHistoryCompare = "ios.edit_history_compare"
    }

    public enum Schema: String, Codable {
        case editHistoryCompare = "/analytics/mobile_apps/ios_edit_history_compare/1.0.0"
    }
}

