import Foundation

struct WKFindAndReplaceViewModel {

    enum Configuration {
        case findOnly
        case findAndReplace
    }
    
    var currentMatchInfo: String?
    
    let configuration: Configuration = .findAndReplace
    
    mutating func reset() {
        currentMatchInfo = nil
    }
}
